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

@interface CKIncrementalMountComponent ()

- (void)mountVisibleChildren;

@end

@implementation CKIncrementalMountComponent
{
  CKComponent *_component;

  // Main-thread only. Mutable mount-based state. These parameters will be
  // empty when not mounted.
  CKComponentLayout _mountedChildLayout;
  NSSet<CKComponent *> *_currentlyMountedComponents;
}

+ (instancetype)newWithComponent:(CKComponent *)component
{
  CKComponentScope scope(self);

  CKIncrementalMountComponent *c =
  [super
   newWithView:{
     [UIView class]
   }
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
  _mountedChildLayout = children->at(0).layout;
  return result;
}

- (void)unmount
{
  [super unmount];
  CKUnmountComponents(_currentlyMountedComponents);
  _currentlyMountedComponents = nil;
  _mountedChildLayout = {};
}

- (void)mountVisibleChildren
{
  CKAssertMainThread();

  if (!self.viewContext.view) {
    return;
  }

  UIView *const view = self.viewContext.view;
  const CGRect bounds = view.bounds;
  const CGRect visibleWindowBounds = [view convertRect:view.window.bounds
                                              fromView:view.window];
  // Within the coordinate-space of this component's mounted view.
  const CGRect visibleBounds = CGRectIntersection(bounds, visibleWindowBounds);

  // Enumerate over all children, and identify which ones intersect with the
  // current visible rect.

  std::vector<CKComponentLayoutChild> visibleChildren;
  BOOL needsUpdate = NO;
  for (const auto &child : *_mountedChildLayout.children) {
    const CGRect childFrame = CGRectMake(child.position.x,
                                         child.position.y,
                                         child.layout.size.width,
                                         child.layout.size.height);
    const CGRect childIntersection = CGRectIntersection(childFrame, visibleBounds);
    if (!CGRectIsNull(childIntersection) && !CGRectIsEmpty(childIntersection)) {
      visibleChildren.push_back(child);
      if (![_currentlyMountedComponents containsObject:child.layout.component]) {
        needsUpdate = YES;
      }
    }
  }

  if (!needsUpdate) {
    // We don't need to re-mount since there are no new components visible. We
    // only remove components when new ones come within the viewport.
    return;
  }

  // Mount if not already mounted.
  _currentlyMountedComponents =
  CKMountComponentLayout({ _component, _mountedChildLayout.size, visibleChildren, nil },
                         view,
                         _currentlyMountedComponents,
                         self,
                         CK::Component::MountContext::RootContext(view));
}

@end

@interface CKIncrementalMountComponentController : CKComponentController<CKIncrementalMountComponent *>

@end

@implementation CKIncrementalMountComponentController
{

}

- (void)viewDidScroll
{
  [super viewDidScroll];
  [self.component mountVisibleChildren];
}

- (void)didMount
{
  [super didMount];
  [self.component mountVisibleChildren];
}

@end
