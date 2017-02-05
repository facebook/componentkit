//
//  CKIncrementalMountComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 1/28/17.
//
//

#import "CKIncrementalMountComponent.h"

#import <unordered_set>

#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/ComponentViewManager.h>
#import <ComponentKit/CKComponentContext.h>
#import <ComponentKit/CKFunctor.h>

#import "CKScrollAnnouncingView.h"

struct _CKIncrementalMountResult {
  NSSet *mountedComponents;
  std::vector<CK::Component::ViewReusePoolMap::VendedViewCheckout> checkedOutViews;
};

typedef std::unordered_set<CKComponent *, CK::HashFunctor<id>, CK::EqualFunctor<id>> _CKComponentSet;
typedef std::unordered_map<CKComponent *, _CKIncrementalMountResult, CK::HashFunctor<id>, CK::EqualFunctor<id>> _CKMountedComponentResultMap;

static NSArray *addListenerForParentScrollViews(id<CKScrollListener> listener, UIView *view)
{
  UIView *currentView = view;
  NSMutableArray *tokens = [NSMutableArray array];
  while (currentView) {
    if ([currentView isKindOfClass:[UIScrollView class]]) {
      [tokens addObject:[(UIScrollView *)currentView ck_addScrollListener:listener]];
    }
    currentView = [currentView superview];
  }
  return tokens;
}

class _CKViewReusePoolMapCheckoutContext {
  CK::Component::ViewReusePoolMap &_reusePoolMap;
public:
  _CKViewReusePoolMapCheckoutContext(CK::Component::ViewReusePoolMap &reusePoolMap) : _reusePoolMap(reusePoolMap)
  {
    _reusePoolMap.pushCheckoutContext();
  };
  ~_CKViewReusePoolMapCheckoutContext()
  {
    _reusePoolMap.popCheckoutContext();
  };

  _CKViewReusePoolMapCheckoutContext(const _CKViewReusePoolMapCheckoutContext&) = delete;
  _CKViewReusePoolMapCheckoutContext(_CKViewReusePoolMapCheckoutContext&&) = delete;
};

struct _CKIncrementalMountVisibleChild {
  CGRect frame;
  // Pointer into the full layout struct held by the visible child controller.
  const CKComponentLayoutChild *layout;

  bool intersects(const CGRect &rect) const
  {
    const CGRect intersection = CGRectIntersection(frame, rect);
    return !CGRectIsNull(intersection) && !CGRectIsEmpty(intersection);
  }
};

struct _CKIncrementalMountVisibleChildPartition {
  CGRect frame;
  std::vector<_CKIncrementalMountVisibleChild> children;

  bool intersects(const CGRect &rect) const
  {
    const CGRect intersection = CGRectIntersection(frame, rect);
    return !CGRectIsNull(intersection) && !CGRectIsEmpty(intersection);
  }
};

class _CKIncrementalMountVisibilityController {
  CKComponentLayout _layout;
  std::vector<_CKIncrementalMountVisibleChildPartition> _partitions;

public:
  _CKIncrementalMountVisibilityController() : _layout({}) {};
  _CKIncrementalMountVisibilityController(const CKComponentLayout &l) : _layout(l)
  {
    // We want at most 10 child layouts per bucket, we can't guarantee that the children are all spatially distributed,
    // but we still try our best here. The idea is that searching for children that overlap with a rect takes 1/10th of
    // the time for spatially-distributed children, and the cost for non-spatially-distributed children isn't impacted.
    const size_t numberOfPartitions = _layout.children->size() / 10 + 1;
    // Now we take the total bounds of the layout, and divide it into that many rectangular slices along the longest
    // dimension.
    if (_layout.size.width > _layout.size.height) {
      const CGFloat advance = _layout.size.width / (CGFloat)numberOfPartitions;
      for (size_t i = 0; i < numberOfPartitions; i++) {
        const CGRect partitionRect = CGRectMake(advance * (CGFloat)i, 0, advance, _layout.size.height);
        _partitions.push_back({partitionRect, {}});
      }
    } else {
      const CGFloat advance = _layout.size.height / (CGFloat)numberOfPartitions;
      for (size_t i = 0; i < numberOfPartitions; i++) {
        const CGRect partitionRect = CGRectMake(0, advance * (CGFloat)i, _layout.size.width, advance);
        _partitions.push_back({partitionRect, {}});

      }
    }
    for (const auto &c : *_layout.children) {
      const CGRect childFrame = CGRectMake(c.position.x,
                                           c.position.y,
                                           c.layout.size.width,
                                           c.layout.size.height);
      for (auto &partition : _partitions) {
        if (CGRectIntersectsRect(childFrame, partition.frame)) {
          // Remember, a single child can be in multiple partitions if they straddle a boundary
          partition.children.push_back({childFrame, &c});
        }
      }
    }
  };

  CGSize size() const {
    return _layout.size;
  };

  struct VisibleChildren {
    _CKComponentSet allVisibleComponents;
    std::vector<CKComponentLayoutChild> newlyVisibleChildren;
  };

  bool areNewChildrenVisible(const CGRect &bounds, const _CKMountedComponentResultMap &previouslyVisible) const
  {
    // Makes no allocations. This method has to remain fast since it is executed on every scroll tick
    for (const auto &partition : _partitions) {
      if (partition.intersects(bounds)) {
        for (const auto &c : partition.children) {
          if (c.intersects(bounds)
              && previouslyVisible.find(c.layout->layout.component) == previouslyVisible.end()) {
            return true;
          }
        }
      }
    }
    return false;
  }

  VisibleChildren visibleChildren(const CGRect &bounds, const _CKMountedComponentResultMap &previouslyVisible) const
  {
    VisibleChildren output;
    std::unordered_set<const CKComponentLayoutChild *> visitedChildren;

    for (const auto &partition : _partitions) {
      if (partition.intersects(bounds)) {
        for (const auto &c : partition.children) {
          if (c.intersects(bounds)
              && visitedChildren.find(c.layout) == visitedChildren.end()) {
            visitedChildren.insert(c.layout);
            if (previouslyVisible.find(c.layout->layout.component) == previouslyVisible.end()) {
              output.newlyVisibleChildren.push_back(*c.layout);
            }
            output.allVisibleComponents.insert(c.layout->layout.component);
          }
        }
      }
    }
    return output;
  }
};

class _CKIncrementalMountController {
  CKComponent *_childComponent;
  CKComponent *__weak _superComponent;
  UIView *_view;
  _CKIncrementalMountVisibilityController _visibilityController;
  struct {
    CGPoint position;
    UIEdgeInsets layoutGuide;
  } _mountInfo;
  _CKMountedComponentResultMap _mountedComponentResultMap;

public:

  void unmountAllChildren(void)
  {
    if (!_view) {
      return;
    }
    CK::Component::ViewReusePoolMap &reusePoolMap =
    CK::Component::ViewReusePoolMap::alternateReusePoolMapForView(_view, "CKIncrementalMountComponent");
    for (const auto &mountResult : _mountedComponentResultMap) {
      CKUnmountComponents(mountResult.second.mountedComponents);
      reusePoolMap.checkInVendedViews(mountResult.second.checkedOutViews);
    }
    _mountedComponentResultMap.clear();
  }

  void checkInAllViewsForReuse(void)
  {
    if (!_view) {
      return;
    }
    CK::Component::ViewReusePoolMap &reusePoolMap =
    CK::Component::ViewReusePoolMap::alternateReusePoolMapForView(_view, "CKIncrementalMountComponent");
    for (auto &mountResult : _mountedComponentResultMap) {
      reusePoolMap.checkInVendedViews(mountResult.second.checkedOutViews);
      mountResult.second.checkedOutViews.clear();
    }
  }

  void mountVisibleChildren(void)
  {
    if (!_view) {
      return;
    }
    UIView *rootView = _view.window;
    if (!rootView) {
      rootView = _view;
      // We're not in a window yet, so we just traverse upwards until we find a root. This commonly
      // happens when a cell is initially being returned for a collection view.
      while ([rootView superview]) {
        rootView = [rootView superview];
      }
    }
    const CGRect visibleBounds = [rootView convertRect:rootView.bounds
                                                      toView:_view];

    if (!_visibilityController.areNewChildrenVisible(visibleBounds, _mountedComponentResultMap)) {
      return;
    }

    _CKIncrementalMountVisibilityController::VisibleChildren visibleChildren =
    _visibilityController.visibleChildren(visibleBounds, _mountedComponentResultMap);

    CKCAssert(!visibleChildren.newlyVisibleChildren.empty(), @"Should have newly visible children");

    CK::Component::ViewReusePoolMap &reusePoolMap =
    CK::Component::ViewReusePoolMap::alternateReusePoolMapForView(_view, "CKIncrementalMountComponent");
    CK::Component::MountContext mountContext = CK::Component::MountContext
    (std::make_shared<CK::Component::ViewManager>
     (_view, reusePoolMap),
     _mountInfo.position,
     _mountInfo.layoutGuide,
     NO);

    for (auto it = _mountedComponentResultMap.begin(); it != _mountedComponentResultMap.end();) {
      if (visibleChildren.allVisibleComponents.find(it->first) == visibleChildren.allVisibleComponents.end()) {
        CKUnmountComponents(it->second.mountedComponents);
        reusePoolMap.checkInVendedViews(it->second.checkedOutViews);
        it = _mountedComponentResultMap.erase(it);
      } else {
        ++it;
      }
    }

    // Mount if not already mounted.
    for (const auto &c : visibleChildren.newlyVisibleChildren) {
      _CKViewReusePoolMapCheckoutContext context(reusePoolMap);
      _CKIncrementalMountResult &result = _mountedComponentResultMap[c.layout.component];
      result.mountedComponents = CKMountComponentLayout({ _childComponent, _visibilityController.size(), {c}, nil },
                                                        _view,
                                                        result.mountedComponents,
                                                        _superComponent,
                                                        mountContext);
      CKCAssert(result.checkedOutViews.empty(), @"Overwriting views");
      result.checkedOutViews = reusePoolMap.checkOutVendedViews();
    }
  }

  _CKIncrementalMountController() {};
  _CKIncrementalMountController(CKComponent *childComponent,
                                CKComponent *superComponent,
                                UIView *view,
                                const CKComponentLayout &layout,
                                CGPoint position,
                                UIEdgeInsets layoutGuide) :
  _childComponent(childComponent),
  _superComponent(superComponent),
  _view(view),
  _visibilityController(layout),
  _mountInfo({position, layoutGuide}) {};
};

@interface CKIncrementalMountComponent () <CKScrollListener>

- (void)unmountChildren;

@end

static NSString *kIncrementalMountVisibleChildControllerWrapperKey = @"_CKIncrementalMountVisibleChildController";

@implementation CKIncrementalMountComponent
{
  CKComponent *_component;

  // Main-thread only. Mutable mount-based state. These parameters will be
  // empty when not mounted.
  _CKIncrementalMountController _mountController;
  NSArray<CKScrollListeningToken *> *_scrollListeningTokens;
}

+ (instancetype)newWithComponent:(CKComponent *)component
{
  if (!component) {
    return nil;
  }

  CKComponentScope scope(self);

  CKIncrementalMountComponent *c =
  [super
   newWithView:{[UIView class]}
   size:{}];
  if (c) {
    c->_component = component;
  }
  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKComponentLayout l = [_component layoutThatFits:constrainedSize parentSize:parentSize];
  return {self, l.size, {{{0,0}, l}}};
}

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent
{
  // On re-mount we have to drop our views back into the reuse pool and re-render everything
  _mountController.checkInAllViewsForReuse();

  CK::Component::MountResult result = [super mountInContext:context
                                                       size:size
                                                   children:children
                                             supercomponent:supercomponent];

  result.mountChildren = NO;
  if (children && !children->empty()) {
    _mountController = {
      _component,
      self,
      self.viewContext.view,
      children->at(0).layout,
      result.contextForChildren.position,
      result.contextForChildren.layoutGuide
    };
  } else {
    _mountController = {};
  }
  _scrollListeningTokens = addListenerForParentScrollViews(self, self.viewContext.view);
  _mountController.mountVisibleChildren();
  return result;
}

- (void)unmount
{
  _mountController.checkInAllViewsForReuse();

  [super unmount];

  for (CKScrollListeningToken *token in _scrollListeningTokens) {
    [token removeListener];
  }
}

- (void)unmountChildren
{
  CKAssertMainThread();
  _mountController.unmountAllChildren();
}

#pragma mark - CKScrollListener

- (void)scrollViewDidScroll
{
  CKAssertMainThread();
  if (!self.viewContext.view) {
    return;
  }

  _mountController.mountVisibleChildren();
}

@end

@interface CKIncrementalMountComponentController : CKComponentController <CKIncrementalMountComponent *>

@end

@implementation CKIncrementalMountComponentController
{
  CKIncrementalMountComponent *_oldComponent;
}

- (void)willUnmount
{
  [super willUnmount];
  [self.component unmountChildren];
}

- (void)didUpdateComponent
{
  [super didUpdateComponent];
  [_oldComponent unmountChildren];
  _oldComponent = nil;
}

- (void)willUpdateComponent
{
  [super willUpdateComponent];
  _oldComponent = self.component;
}

@end
