/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentLayout.h"

#import <stack>

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import "ComponentUtilities.h"
#import "CKComponentInternal.h"

using namespace CK::Component;

void CKOffMainThreadDeleter::operator()(std::vector<CKComponentLayoutChild> *target)
{
  if ([NSThread isMainThread]) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      delete target;
    });
  } else {
    delete target;
  }
}

NSSet *CKMountComponentLayout(const CKComponentLayout &layout,
                              UIView *view,
                              NSSet *previouslyMountedComponents,
                              CKComponent *supercomponent)
{
  struct MountItem {
    const CKComponentLayout &layout;
    MountContext mountContext;
    CKComponent *supercomponent;
    BOOL visited;
  };
  // Using a stack to mount ensures that the components are mounted
  // in a DFS fashion which is handy if you want to animate a subpart
  // of the tree
  std::stack<MountItem> stack;
  stack.push({layout, MountContext::RootContext(view), supercomponent, NO});
  NSMutableSet *mountedComponents = [NSMutableSet set];

  layout.component.rootComponentMountedView = view;

  while (!stack.empty()) {
    MountItem &item = stack.top();
    if (item.visited) {
      [item.layout.component childrenDidMount];
      stack.pop();
    } else {
      item.visited = YES;
      if (item.layout.component == nil) {
        continue; // Nil components in a layout struct are invalid, but handle them gracefully
      }
      const MountResult mountResult = [item.layout.component mountInContext:item.mountContext
                                                                       size:item.layout.size
                                                                   children:item.layout.children
                                                             supercomponent:item.supercomponent];
      [mountedComponents addObject:item.layout.component];

      if (mountResult.mountChildren) {
        // Ordering of components should correspond to ordering of mount. Push components on backwards so the
        // bottom-most component is mounted first.
        for (auto riter = item.layout.children->rbegin(); riter != item.layout.children->rend(); riter ++) {
          stack.push({riter->layout, mountResult.contextForChildren.offset(riter->position, item.layout.size, riter->layout.size), item.layout.component, NO});
        }
      }
    }
  }

  if (previouslyMountedComponents) {
    // Unmount any components that were in previouslyMountedComponents but are no longer in mountedComponents.
    NSMutableSet *componentsToUnmount = [previouslyMountedComponents mutableCopy];
    [componentsToUnmount minusSet:mountedComponents];
    CKUnmountComponents(componentsToUnmount);
  }

  return mountedComponents;
}

void CKUnmountComponents(NSSet *componentsToUnmount)
{
  for (CKComponent *component in componentsToUnmount) {
    [component unmount];
  }
}