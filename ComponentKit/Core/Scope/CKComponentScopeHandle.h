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

#if CK_NOT_SWIFT

/** Creates a conceptually brand new scope handle */
- (instancetype)initWithListener:(id<CKComponentStateListener> _Nullable)listener
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
               componentTypeName:(const char *)componentTypeName
                    initialState:(id _Nullable)initialState;

/** Creates a new instance of the scope handle that incorporates the given state updates. */
- (instancetype)newHandleWithStateUpdates:(const CKComponentStateUpdateMap &)stateUpdates;

/** Enqueues a state update to be applied to the scope with the given mode. */
- (void)updateState:(id _Nullable (^)(id _Nullable))updateBlock
           metadata:(const CKStateUpdateMetadata &)metadata
               mode:(CKUpdateMode)mode;

/** Replaces the state for this handle. May only be called *before* resolution. */
- (void)replaceState:(id _Nullable)state;

/** Informs the scope handle that it should complete its configuration. This will generate the controller */
- (void)resolveInScopeRoot:(CKComponentScopeRoot *)scopeRoot;

/** Registers the component and its controller in the scope root */
- (void)registerInScopeRoot:(CKComponentScopeRoot *)scopeRoot;

/** Resolves the component and registers the component and its controller in the scope root */
- (void)resolveAndRegisterInScopeRoot:(CKComponentScopeRoot *)scopeRoot;

/** Acquire component if possible, assert if the scope handle is wrong */
- (BOOL)acquireFromComponent:(id<CKComponentProtocol>)component;

/** Force acquire component, assert if the scope handle is wrong */
- (void)forceAcquireFromComponent:(id<CKComponentProtocol>)component;

/** Clears the acquired component. Used in some cases for render to nil. */
- (void)relinquishComponent;

/**
 Should not be called until after nodeForComponent(). The controller will assert (if assertions are compiled), and
 return nil until `resolve` is called.
 */
@property (nonatomic, strong, readonly, nullable) id<CKComponentControllerProtocol> controller;

@property (nonatomic, assign, readonly) const char* componentTypeName;

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

#endif

@end

#if CK_NOT_SWIFT

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

#endif

typedef int32_t CKScopedResponderUniqueIdentifier;

NS_SWIFT_NAME(ScopedResponderKey)
typedef int CKScopedResponderKey;

NS_SWIFT_NAME(ScopedResponder)
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
