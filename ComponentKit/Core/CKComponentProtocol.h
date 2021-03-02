/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>
#import <ComponentKit/CKDefines.h>
#import <ComponentKit/RCComponentCoalescingMode.h>
#import <ComponentKit/CKBuildComponentTreeParams.h>
#import <ComponentKit/RCIterable.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CKComponentControllerProtocol;
@class CKComponentScopeHandle;
@class CKTreeNode;

NS_SWIFT_NAME(ComponentProtocol)
@protocol CKComponentProtocol <RCIterable>

@property (nonatomic, copy, readonly) NSString *className;
@property (nonatomic, assign, readonly) const char *typeName;
@property (nonatomic, strong, readonly, class, nullable) id initialState;
@property (nonatomic, strong, readonly, class, nullable) Class<CKComponentControllerProtocol> controllerClass;
@property (nonatomic, assign, readonly, class) RCComponentCoalescingMode coalescingMode;

/*
 * For internal use only. Please do not use this. Will soon be deprecated.
 * Overriding this API has undefined behvaiour.
 */
- (id<CKComponentControllerProtocol>)buildController;

/** Reference to the component's scope handle. */
@property (nonatomic, strong, readonly, nullable) CKComponentScopeHandle *scopeHandle;

#if CK_NOT_SWIFT

/**
 This method translates the component render method into a 'CKTreeNode'; a component tree.
 It's being called by the infra during the component tree creation.
 */
- (void)buildComponentTree:(CKTreeNode *)parent
            previousParent:(CKTreeNode *_Nullable)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate;

#endif

/** Ask the component to acquire a tree node. */
- (void)acquireTreeNode:(CKTreeNode *)treeNode;

/** Reference to the component's tree node. */
@property (nonatomic, strong, readonly, nullable) CKTreeNode *treeNode;

/** Get child at index; can be nil */
- (id<CKComponentProtocol> _Nullable)childAtIndex:(unsigned int)index;

@end

NS_ASSUME_NONNULL_END
