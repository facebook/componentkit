//
//  CKIncrementalMountComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 1/28/17.
//
//

#import "CKIncrementalMountComponent.h"

#import <set>

#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/ComponentViewManager.h>
#import <ComponentKit/CKComponentContext.h>

#import "CKScrollAnnouncingView.h"

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

@interface CKIncrementalMountComponent () <CKScrollListener>

@end

@implementation CKIncrementalMountComponent
{
  CKComponent *_component;

  // Main-thread only. Mutable mount-based state. These parameters will be
  // empty when not mounted.
  CKComponentLayout _mountedChildLayout;
  CGPoint _mountedPosition;
  UIEdgeInsets _mountedLayoutGuide;
  NSArray<CKScrollListeningToken *> *_scrollListeningTokens;
  NSSet<CKComponent *> *_currentlyMountedComponents;
  std::vector<CK::Component::ViewReusePoolMap::VendedViewCheckout> _checkedOutViews;
}

+ (instancetype)newWithComponent:(CKComponent *)component
{
  if (!component) {
    return nil;
  }

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
  CK::Component::MountResult result = [super mountInContext:context
                                                       size:size
                                                   children:children
                                             supercomponent:supercomponent];
  result.mountChildren = NO;
  _currentlyMountedComponents = nil;
  _mountedChildLayout = children->at(0).layout;
  _scrollListeningTokens = addListenerForParentScrollViews(self, self.viewContext.view);
  _mountedPosition = result.contextForChildren.position;
  [self mountVisibleChildren];
  return result;
}

- (void)unmount
{
  if (!_checkedOutViews.empty() && self.viewContext.view) {
    CK::Component::ViewReusePoolMap &reusePoolMap = CK::Component::ViewReusePoolMap::alternateReusePoolMapForView(self.viewContext.view, "CKIncrementalMountComponent");
    reusePoolMap.checkInVendedViews(_checkedOutViews);
    _checkedOutViews.clear();
  }

  [super unmount];

  _currentlyMountedComponents = nil;
  for (CKScrollListeningToken *token in _scrollListeningTokens) {
    [token removeListener];
  }
}

- (void)mountVisibleChildren
{
  CKAssertMainThread();

  UIView *const view = self.viewContext.view;

  if (!view || view.isHidden) {
    return;
  }

  UIView *rootView = view.window;
  if (!rootView) {
    rootView = view;
    // We're not in a window yet, so we just traverse upwards until we find a root. This commonly
    // happens when a cell is initially being returned for a collection view.
    while ([rootView superview]) {
      rootView = [rootView superview];
    }
  }
  const CGRect visibleWindowBounds = [rootView convertRect:rootView.bounds
                                                    toView:view];

  // Enumerate over all children, and identify which ones intersect with the
  // current visible rect.

  NSMutableSet *visibleChildrenComponents = [NSMutableSet set];

  std::vector<CKComponentLayoutChild> visibleChildren;
  for (auto it = _mountedChildLayout.children->begin(); it != _mountedChildLayout.children->end(); it++) {
    const CGRect childFrame = CGRectMake(it->position.x,
                                         it->position.y,
                                         it->layout.size.width,
                                         it->layout.size.height);
    const CGRect childIntersection = CGRectIntersection(childFrame, visibleWindowBounds);
    if (!CGRectIsNull(childIntersection) && !CGRectIsEmpty(childIntersection)) {
      if (![_currentlyMountedComponents containsObject:it->layout.component]) {
        visibleChildren.push_back(*it);
      }
      [visibleChildrenComponents addObject:it->layout.component];
    }
  }

  if (visibleChildren.empty()) {
    // We don't need to re-mount since there are no new components visible. We
    // only remove components when new ones come within the viewport.
    return;
  }

  CK::Component::ViewReusePoolMap &reusePoolMap = CK::Component::ViewReusePoolMap::alternateReusePoolMapForView(view, "CKIncrementalMountComponent");
  CK::Component::MountContext mountContext = CK::Component::MountContext
  (std::make_shared<CK::Component::ViewManager>
   (self.viewContext.view, reusePoolMap),
   _mountedPosition,
   _mountedLayoutGuide,
   NO);

  std::vector<CK::Component::ViewReusePoolMap::VendedViewCheckout> toAddBackToReusePool;
  for (auto it = _checkedOutViews.begin(); it != _checkedOutViews.end(); it++) {
    const CGRect viewIntersection = CGRectIntersection([it->view frame], visibleWindowBounds);
    if (CGRectIsNull(viewIntersection) || CGRectIsEmpty(viewIntersection)) {
      toAddBackToReusePool.push_back(*it);
      _checkedOutViews.erase(it--);
    }
  }
  if (!toAddBackToReusePool.empty()) {
    reusePoolMap.checkInVendedViews(toAddBackToReusePool);
  }

  // Mount if not already mounted.
  CKMountComponentLayout({ _component, _mountedChildLayout.size, visibleChildren, nil },
                         view,
                         nil,
                         self,
                         mountContext);

  _currentlyMountedComponents = visibleChildrenComponents;
  std::vector<CK::Component::ViewReusePoolMap::VendedViewCheckout> checkout = reusePoolMap.checkOutVendedViews();
  _checkedOutViews.insert(_checkedOutViews.end(), checkout.begin(), checkout.end());
}

#pragma mark - CKScrollListener

- (void)scrollViewDidScroll
{
  CKAssertMainThread();
  if (!self.viewContext.view) {
    return;
  }

  [self mountVisibleChildren];
}

@end
