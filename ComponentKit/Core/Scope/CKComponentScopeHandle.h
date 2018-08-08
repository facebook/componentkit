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

#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKComponentControllerProtocol.h>
#import <ComponentKit/CKStateUpdateMetadata.h>
#import <ComponentKit/CKUpdateMode.h>

@class CKComponent;
@class CKComponentScopeRoot;
@class CKScopedResponder;

@protocol CKComponentStateListener;
@protocol CKComponentProtocol;
@protocol CKTreeNodeProtocol;

@interface CKComponentScopeHandle<__covariant ControllerType:id<CKComponentControllerProtocol>> : NSObject

/**
 This method looks to see if the currently defined scope matches that of the given component; if so it returns the
 handle corresponding to the current scope. Otherwise it returns nil.
 This is only meant to be called when constructing a component and as part of the implementation itself.
 */
+ (instancetype)handleForComponent:(id<CKComponentProtocol>)component;

/** Creates a conceptually brand new scope handle */
- (instancetype)initWithListener:(id<CKComponentStateListener>)listener
                  rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
                  componentClass:(Class<CKComponentProtocol>)componentClass
                    initialState:(id)initialState
                          parent:(CKComponentScopeHandle *)parent;

/** Creates a new instance of the scope handle that incorporates the given state updates. */
- (instancetype)newHandleWithStateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                       componentScopeRoot:(CKComponentScopeRoot *)componentScopeRoot
                                   parent:(CKComponentScopeHandle *)parent;

/** Creates a new, but identical, instance of the scope handle that will be reacquired due to a scope collision. */
- (instancetype)newHandleToBeReacquiredDueToScopeCollision;

/** Enqueues a state update to be applied to the scope with the given mode. */
- (void)updateState:(id (^)(id))updateBlock
           metadata:(const CKStateUpdateMetadata &)metadata
               mode:(CKUpdateMode)mode;

/** Replaces the state for this handle. May only be called *before* resolution. */
- (void)replaceState:(id)state;

/** Informs the scope handle that it should complete its configuration. This will generate the controller */
- (void)resolve;

/** Acquire component, assert if the scope handle is wrong */
- (void)forceAcquireFromComponent:(id<CKComponentProtocol>)component;

/** Set the tree node of the acquired component. May only be called *before* resolution. */
- (void)setTreeNode:(id<CKTreeNodeProtocol>)treeNode;

/**
 Should not be called until after handleForComponent:. The controller will assert (if assertions are compiled), and
 return nil until `resolve` is called.
 */
@property (nonatomic, strong, readonly) ControllerType controller;

@property (nonatomic, assign, readonly) Class<CKComponentProtocol> componentClass;

@property (nonatomic, strong, readonly) id state;
@property (nonatomic, readonly) CKComponentScopeHandleIdentifier globalIdentifier;
@property (nonatomic, readonly, weak) id<CKComponentProtocol> acquiredComponent;
@property (nonatomic, weak, readonly) CKComponentScopeHandle *parent;
@property (nonatomic, weak, readonly) id<CKTreeNodeProtocol> treeNode;

/**
 Provides a responder corresponding with this scope handle. The controller will assert if called before resolution.
 */
- (CKScopedResponder *)scopedResponder;

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
- (CKScopedResponderKey)keyForHandle:(CKComponentScopeHandle *)handle;

/**
 Returns the proper responder based on the key provided.
 */
- (id)responderForKey:(CKScopedResponderKey)key;

@end
