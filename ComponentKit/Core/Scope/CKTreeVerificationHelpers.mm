/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTreeVerificationHelpers.h"

#import <queue>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMountable.h>
#import <ComponentKit/RCComponentDescriptionHelper.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKRootTreeNode.h>
#import <ComponentKit/CKEmptyComponent.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static NSArray<id<CKMountable>> *generateComponentBacktrace(id<CKMountable> component,
                                                          NSMapTable<id<CKMountable>, id<CKMountable>> *componentsToParentComponents)
{
  NSMutableArray<id<CKMountable>> *componentBacktrace = [NSMutableArray arrayWithObject:component];
  auto parentComponent = [componentsToParentComponents objectForKey:component];
  while (parentComponent) {
    [componentBacktrace addObject:parentComponent];
    parentComponent = [componentsToParentComponents objectForKey:parentComponent];
  }
  return componentBacktrace;
}

CKDuplicateComponentInfo CKFindDuplicateComponent(const RCLayout &layout)
{
  std::queue<const RCLayout> queue;
  NSMutableSet<id<NSObject>> *const previouslySeenComponent = [NSMutableSet new];
  NSMapTable<id<CKMountable>, id<CKMountable>> *const componentsToParentComponents = [NSMapTable strongToStrongObjectsMapTable];
  queue.push(layout);
  while (!queue.empty()) {
    const auto componentLayout = queue.front();
    queue.pop();
    auto const component = componentLayout.component;

    if (component.class == CKEmptyComponent.class) {
      continue;
    }

    if (component && [previouslySeenComponent containsObject:component]) {
      return {
        .component = component,
        .backtraceDescription = RCComponentBacktraceDescription(generateComponentBacktrace(component, componentsToParentComponents)),
      };
    }
    if (component) {
      [previouslySeenComponent addObject:component];
    }
    if (componentLayout.children) {
      for (const auto& childComponentLayout : *componentLayout.children) {
        queue.push(childComponentLayout.layout);
        [componentsToParentComponents setObject:componentLayout.component forKey:childComponentLayout.layout.component];
      }
    }
  }
  return {};
}

void CKDetectDuplicateComponent(const RCLayout &layout) {
#if CK_ASSERTIONS_ENABLED
  auto const info = CKFindDuplicateComponent(layout);
  if (info.component) {
    CKCFailAssertWithCategory(RCComponentCompactDescription(info.component),
                              @"Duplicate component in the tree. Attempting to use %@ more than once in the component tree can lead to an incorrect and unexpected behavior\n"
                              @"Please make sure to create another instance of %@ if needed. \nComponent backtrace:\n%@",
                              info.component.className,
                              info.component.className,
                              info.backtraceDescription);
  }
#endif
}

#if CK_ASSERTIONS_ENABLED
static void CKVerifyTreeNodeWithParent(const CKRootTreeNode &rootNode, const RCLayout &layout, id<CKTreeNodeProtocol> parentNode)
{
  if (layout.component == nil) {
    return;
  }

  id<CKTreeNodeProtocol> treeNode = nil;
  if ([layout.component isKindOfClass:[CKComponent class]]) {
    auto const c = (CKComponent *)layout.component;
    if (c.treeNode) {
      treeNode = c.treeNode;
      auto const registeredParentNode = rootNode.parentForNodeIdentifier(treeNode.nodeIdentifier);
      if (registeredParentNode == nil) {
        CKCFailAssertWithCategory(RCComponentCompactDescription(c),
                                  @"Missing link from node to its parent on the CKRootTreeNode; \n"
                                  @"make sure your component returns all its children on the RCIterable methods.\n"
                                  @"Component:%@\n"
                                  @"Parent component:%@",
                                  c,
                                  parentNode.component);
      } else if (registeredParentNode != parentNode) {
        CKCFailAssertWithCategory(RCComponentCompactDescription(c),
                                  @"Incorrect link from node to its parent on the CKRootTreeNode; \n"
                                  @"make sure your component returns all its children on the RCIterable methods.\n"
                                  @"Component:%@\n"
                                  @"Parent component:%@\n"
                                  @"Registered parent component:%@",
                                  c,
                                  parentNode.component,
                                  registeredParentNode.component);
      }
    }
  }

  // Continue the check on the children; if the component has no tree node, pass the previous one.
  if (layout.children) {
    for (const auto &childLayout : *layout.children) {
      CKVerifyTreeNodeWithParent(rootNode, childLayout.layout, treeNode ?: parentNode);
    }
  }
}

#endif

void CKVerifyTreeNodesToParentLinks(CKComponentScopeRoot *scopeRoot, const RCLayout &layout)
{
  #if CK_ASSERTIONS_ENABLED
  if (scopeRoot.hasRenderComponentInTree) {
    CKVerifyTreeNodeWithParent(scopeRoot.rootNode, layout, scopeRoot.rootNode.node());
  }
  #endif
}

#pragma clang diagnostic pop
