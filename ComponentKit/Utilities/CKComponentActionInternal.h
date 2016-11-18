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

#import <vector>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKComponentScope.h>

#import <type_traits>

@class CKComponent;

/**
 We support several different types of action variants. You don't need to use this value anywhere, it's set for you
 by whatever initializer you end up using.
 */
typedef NS_ENUM(NSUInteger, CKTypedComponentActionVariant) {
  CKTypedComponentActionVariantRawSelector = 0,
  CKTypedComponentActionVariantTargetSelector,
  CKTypedComponentActionVariantComponentScope
};

typedef NS_ENUM(NSUInteger, CKComponentActionSendBehavior) {
  /** Starts searching at the sender's next responder. Usually this is what you want to prevent infinite loops. */
  CKComponentActionSendBehaviorStartAtSenderNextResponder,
  /** If the sender itself responds to the action, invoke the action on the sender. */
  CKComponentActionSendBehaviorStartAtSender,
};

#pragma mark - Action Base

/** A base-class for typed components that doesn't use templates to avoid template bloat. */
class CKTypedComponentActionBase {
protected:
  CKTypedComponentActionBase();
  CKTypedComponentActionBase(id target, SEL selector);
  
  CKTypedComponentActionBase(const CKComponentScope &scope, SEL selector);
  
  /** Legacy constructor for raw selector actions. Traverse up the mount responder chain. */
  CKTypedComponentActionBase(SEL selector);
  
  /** Allows conversion from NULL actions. */
  CKTypedComponentActionBase(int s);
  CKTypedComponentActionBase(long s);
  CKTypedComponentActionBase(std::nullptr_t n);
  
  ~CKTypedComponentActionBase() {};
  
  id initialTarget(CKComponent *sender) const;
  CKComponentActionSendBehavior defaultBehavior() const;
  
  bool operator==(const CKTypedComponentActionBase& rhs) const;
  
  CKTypedComponentActionVariant _variant;
  __weak id _target;
  __weak CKComponentScopeHandle *_scopeHandle;
  SEL _selector;
  
public:
  explicit operator bool() const;
  bool isEqual(const CKTypedComponentActionBase &rhs) const;
  SEL selector() const;
};

#pragma mark - Typed Helpers

template <typename... Ts> struct CKTypedComponentActionTypelist { };

template <bool... b>
struct CKTypedComponentActionBoolPack {};

template <typename... TS>
struct CKTypedComponentActionDenyType : std::true_type {};

/** Base case, recursion should stop here. */
void CKTypedComponentActionTypeVectorBuild(std::vector<const char *> &typeVector, const CKTypedComponentActionTypelist<> &list);

/**
 Recursion through variadic argument type unpacking. This allows us to build a vector of encoded const char * before
 any actual arguments have been provided. All of this is done at compile-time.
 */
template<typename T, typename... Ts>
void CKTypedComponentActionTypeVectorBuild(std::vector<const char *> &typeVector, const CKTypedComponentActionTypelist<T, Ts...> &list)
{
  typeVector.push_back(@encode(T));
  CKTypedComponentActionTypeVectorBuild(typeVector, CKTypedComponentActionTypelist<Ts...>{});
}

/** Base case, recursion should stop here. */
void CKConfigureInvocationWithArguments(NSInvocation *invocation, NSInteger index);

/**
 Recursion here is through normal variadic argument list unpacking. Unlike above, we have the arguments, so we don't
 require the intermediary struct.
 */
template <typename T, typename... Ts>
void CKConfigureInvocationWithArguments(NSInvocation *invocation, NSInteger index, T t, Ts... args)
{
  // We have to be able to handle methods that take less than the provided number of arguments, since that will cause
  // an exception to be thrown.
  if (index < invocation.methodSignature.numberOfArguments) {
    [invocation setArgument:&t atIndex:index];
    CKConfigureInvocationWithArguments(invocation, index + 1, args...);
  }
}

#pragma mark - Debug Helpers

void _CKTypedComponentDebugCheckComponentScope(const CKComponentScope &scope, SEL selector, const std::vector<const char *> &typeEncodings);

void _CKTypedComponentDebugCheckTargetSelector(id target, SEL selector, const std::vector<const char *> &typeEncodings);

NSString *_CKComponentResponderChainDebugResponderChain(id responder);

#pragma mark - Sending

NSInvocation *CKComponentActionSendResponderInvocationPrepare(SEL selector, id target, CKComponent *sender);

template<typename... T>
static void CKComponentActionSendResponderChain(SEL selector, id target, CKComponent *sender, T... args) {
  NSInvocation *invocation = CKComponentActionSendResponderInvocationPrepare(selector, target, sender);
  // We use a recursive argument unpack to unwrap the variadic arguments in-order on the invocation in a type-safe
  // manner.
  CKConfigureInvocationWithArguments(invocation, 3, args...);
  [invocation invoke];
}
