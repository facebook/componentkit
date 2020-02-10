/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKComponentControllerProtocol.h>
#import <ComponentKit/CKStateUpdateMetadata.h>
#import <ComponentKit/CKTreeNodeTypes.h>
#import <ComponentKit/CKUpdateMode.h>

NS_ASSUME_NONNULL_BEGIN

@class CKComponent;
@class CKComponentScopeRoot;
@class CKScopedResponder;

@protocol CKComponentStateListener;
@protocol CKComponentProtocol;
@protocol CKTreeNodeProtocol;

@interface CKComponentScopeHandle : NSObject

/**
 This method looks to see if the currently defined scope matches that of the given component; if so it returns the
 handle corresponding to the current scope. Otherwise it returns nil.
 This is only meant to be called when constructing a component and as part of the implementation itself.
 */
+ (instancetype)handleForComponent:(id<CKComponentProtocol>)component;

/** Creates a conceptually brand new scope handle */
- (instancetype)initWithListener:(id<CKComponentStateListener> _Nullable)listener
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                  componentClass:(Class<CKComponentProtocol>)componentClass
                    initialState:(id _Nullable)initialState;

/** Creates a new instance of the scope handle that incorporates the given state updates. */
- (instancetype)newHandleWithStateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                       componentScopeRoot:(CKComponentScopeRoot *)componentScopeRoot;

/** Enqueues a state update to be applied to the scope with the given mode. */
- (void)updateState:(id _Nullable (^)(id _Nullable))updateBlock
           metadata:(const CKStateUpdateMetadata &)metadata
               mode:(CKUpdateMode)mode;

/** Replaces the state for this handle. May only be called *before* resolution. */
- (void)replaceState:(id _Nullable)state;

/** Informs the scope handle that it should complete its configuration. This will generate the controller */
- (void)resolve;

/** Acquire component, assert if the scope handle is wrong */
- (void)forceAcquireFromComponent:(id<CKComponentProtocol>)component;

/**
 Should not be called until after handleForComponent:. The controller will assert (if assertions are compiled), and
 return nil until `resolve` is called.
 */
@property (nonatomic, strong, readonly, nullable) id<CKComponentControllerProtocol> controller;

@property (nonatomic, assign, readonly) Class<CKComponentProtocol> componentClass;

@property (nonatomic, strong, readonly, nullable) id state;
@property (nonatomic, assign, readonly) CKComponentScopeHandleIdentifier globalIdentifier;
@property (nonatomic, weak, readonly, nullable) id<CKComponentProtocol> acquiredComponent;
@property (nonatomic, assign, readonly) CKTreeNodeIdentifier treeNodeIdentifier;

/** The tree node of the acquired component. Setter should only be called *before* resolution. */
@property (nonatomic, weak, nullable) id<CKTreeNodeProtocol> treeNode;

/**
 Provides a responder corresponding with this scope handle. The controller will assert if called before resolution.
 */
@property (nonatomic, strong, readonly) CKScopedResponder *scopedResponder;

@end

template<>
struct std::hash<CKComponentScopeHandle *>
{
  size_t operator()(const CKComponentScopeHandle *handle) const
  {
    return (size_t)handle.globalIdentifier;
  }
};

template<>
struct std::equal_to<CKComponentScopeHandle *>
{
  bool operator()(const CKComponentScopeHandle *lhs, const CKComponentScopeHandle *rhs) const
  {
    return lhs.globalIdentifier == rhs.globalIdentifier;
  }
};

typedef int32_t CKScopedResponderUniqueIdentifier;
typedef int CKScopedResponderKey;

@interface CKScopedResponder : NSObject

@property (nonatomic, readonly, assign) CKScopedResponderUniqueIdentifier uniqueIdentifier;

/**
 Returns the key needed to access the responder at a later time.
 */
- (CKScopedResponderKey)keyForHandle:(CKComponentScopeHandle * _Nullable)handle;

/**
 Returns the proper responder based on the key provided.
 */
- (id _Nullable)responderForKey:(CKScopedResponderKey)key;

@end

NS_ASSUME_NONNULL_END

#endif
