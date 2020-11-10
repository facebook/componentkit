/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentViewConfiguration_SwiftBridge.h>
#import <ComponentKit/CKComponentSize_SwiftBridge.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CKSwiftComponentDidInitCallback)(void);
typedef void (^CKSwiftComponentWillMountCallback)(void);
typedef void (^CKSwiftComponentDidUnMountCallback)(void);
typedef void (^CKSwiftComponentWillDisposeCallback)(void);

NS_SWIFT_NAME(SwiftComponentModelSwiftBridge)
@interface CKSwiftComponentModel_SwiftBridge : NSObject

CK_INIT_UNAVAILABLE;

- (instancetype)initWithAnimation:(CAAnimation *_Nullable)animation
            initialMountAnimation:(CAAnimation *_Nullable)initialMountAnimation
            finalUnmountAnimation:(CAAnimation *_Nullable)finalUnmountAnimation
                 didInitCallbacks:(NSArray<CKSwiftComponentDidInitCallback> *_Nullable)didInitCallbacks
               willMountCallbacks:(NSArray<CKSwiftComponentWillMountCallback> *_Nullable)willMountCallbacks
              didUnmountCallbacks:(NSArray<CKSwiftComponentDidUnMountCallback> *_Nullable)didUnmountCallbacks
             willDisposeCallbacks:(NSArray<CKSwiftComponentWillDisposeCallback> *_Nullable)willDisposeCallbacks NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) BOOL requiresController;
@end

/// Base class for all View-issued component. Also used to wrap a regular component when the model isn't empty (lifecycle callbacks etc).
@interface CKSwiftComponent : CKComponent

CK_COMPONENT_INIT_UNAVAILABLE

- (instancetype)initWithSwiftView:(CKComponentViewConfiguration_SwiftBridge *_Nullable)viewConfig
                        swiftSize:(CKComponentSize_SwiftBridge *_Nullable)swiftSize
                            child:(CKComponent *_Nullable)child
                            model:(CKSwiftComponentModel_SwiftBridge *_Nullable)model NS_DESIGNATED_INITIALIZER;

- (instancetype)initFromShellComponent:(CKSwiftComponent *)shellComponent
                                 child:(CKComponent *_Nullable)child NS_DESIGNATED_INITIALIZER;

@end

CK_EXTERN_C_BEGIN

/// Clears the current node from the TLS. To be called only if `CKSwiftCreateScopeHandle` was called.
void CKSwiftPopClass(void);

/// Creates a scope handle associated with the class / identifier.
CKComponentScopeHandle *CKSwiftCreateScopeHandle(Class klass, id _Nullable identifier);

/// Initialises the state for a Swift Component.
/// @param handle The handle associated with the component previously returned from `CKSwiftCreateScopeHandle`.
/// @param index The index of the current state.
void CKSwiftInitializeState(CKComponentScopeHandle *handle, NSInteger index, NS_NOESCAPE id _Nullable (^initialValueProvider)(void));

/// Fetches the current state value. Must be called on the main thread (or from `-body`).
/// @param scopeHandle The handle associated with the component.
/// @param index The index of the current state.
id _Nullable CKSwiftFetchState(CKComponentScopeHandle *scopeHandle, NSInteger index);

/// Updates the state for a Swift Component.
/// @param scopeHandle The handle associated with the component.
/// @param index The index of the current state.
/// @param newValue The new state value.
void CKSwiftUpdateState(CKComponentScopeHandle *scopeHandle, NSInteger index, id _Nullable newValue);

/// Initialises an action.
/// @param klass The class of the component. Used for runtime assertions.
/// @param responder The scoped responder for the action.
/// @param key The key for the action
BOOL CKSwiftInitializeAction(Class klass, CKScopedResponder *_Nullable*_Nonnull responder, CKScopedResponderKey *_Null_unspecified key);


CK_EXTERN_C_END

NS_ASSUME_NONNULL_END
