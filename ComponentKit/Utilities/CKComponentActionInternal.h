/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <vector>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentScopeHandle.h>

#import <type_traits>

@class CKComponent;

typedef id (^CKResponderGenerationBlock)(void);
typedef NS_ENUM(NSUInteger, CKComponentActionSendBehavior) {
  /** Starts searching at the sender's next responder. Usually this is what you want to prevent infinite loops. */
  CKComponentActionSendBehaviorStartAtSenderNextResponder,
  /** If the sender itself responds to the action, invoke the action on the sender. */
  CKComponentActionSendBehaviorStartAtSender,
};

class _CKTypedComponentDebugInitialTarget;

#pragma mark - Action Base

/** A base-class for typed components that doesn't use templates to avoid template bloat. */
class CKActionBase {
  protected:
  
  /**
   We support several different types of action variants. You don't need to use this value anywhere, it's set for you
   by whatever initializer you end up using.
   */
  enum class CKActionVariant {
    RawSelector,
    TargetSelector,
    Responder,
    Block
  };

  CKActionBase() noexcept;
  CKActionBase(id target, SEL selector) noexcept;

  CKActionBase(const CKComponentScope &scope, SEL selector) noexcept;

  /** Legacy constructor for raw selector actions. Traverse up the mount responder chain. */
  CKActionBase(SEL selector) noexcept;
  
  CKActionBase(dispatch_block_t block) noexcept;

  ~CKActionBase() {};

  id initialTarget(CKComponent *sender) const;
  CKComponentActionSendBehavior defaultBehavior() const;

  bool operator==(const CKActionBase& rhs) const;

  // Destroying this field calls objc_destroyWeak. Since this is the only field
  // that runs code on destruction, making this field the first field of this
  // object saves an offset calculation instruction in the destructor.
  __weak id _target;
  std::pair<CKScopedResponderUniqueIdentifier, CKResponderGenerationBlock> _scopeIdentifierAndResponderGenerator;
  dispatch_block_t _block;
  CKActionVariant _variant;
  SEL _selector;

public:
  explicit operator bool() const noexcept;
  bool isEqual(const CKActionBase &rhs) const noexcept {
    return *this == rhs;
  }
  SEL selector() const noexcept;
  dispatch_block_t block() const noexcept;
  std::string identifier() const noexcept;

  friend _CKTypedComponentDebugInitialTarget;
};

#pragma mark - Typed Helpers

template <typename... Ts> struct CKActionTypelist { };

template <bool... b>
struct CKActionBoolPack {};

template <typename... TS>
struct CKActionDenyType : std::true_type {};

/** Base case, recursion should stop here. */
void CKActionTypeVectorBuild(std::vector<const char *> &typeVector, const CKActionTypelist<> &list) noexcept;

/**
 Recursion through variadic argument type unpacking. This allows us to build a vector of encoded const char * before
 any actual arguments have been provided. All of this is done at compile-time.
 */
template<typename T, typename... Ts>
void CKActionTypeVectorBuild(std::vector<const char *> &typeVector, const CKActionTypelist<T, Ts...> &list) noexcept
{
  typeVector.push_back(@encode(T));
  CKActionTypeVectorBuild(typeVector, CKActionTypelist<Ts...>{});
}

/** Base case, recursion should stop here. */
void CKConfigureInvocationWithArguments(NSInvocation *invocation, NSInteger index) noexcept;

/**
 Recursion here is through normal variadic argument list unpacking. Unlike above, we have the arguments, so we don't
 require the intermediary struct.
 */
template <typename T, typename... Ts>
void CKConfigureInvocationWithArguments(NSInvocation *invocation, NSInteger index, T t, Ts... args) noexcept
{
  // We have to be able to handle methods that take less than the provided number of arguments, since that will cause
  // an exception to be thrown.
  if (index < invocation.methodSignature.numberOfArguments) {
    [invocation setArgument:&t atIndex:index];
    CKConfigureInvocationWithArguments(invocation, index + 1, args...);
  }
}

#pragma mark - Debug Helpers

template<typename... T>
class CKAction;

/**
 Get the list of control actions attached to the components view (if it has any), for debug purposes.

 @return map of CKAction<> attached to the specifiec component.
 */
std::unordered_map<UIControlEvents, std::vector<CKAction<UIEvent *>>> _CKComponentDebugControlActionsForComponent(CKComponent *const component);

/**
 Access the initialTarget of an action, for debug purposes.
 */
class _CKTypedComponentDebugInitialTarget {
private:
  CKActionBase &_action;

public:
  _CKTypedComponentDebugInitialTarget(CKActionBase &action) : _action(action) { }

  id get(CKComponent *sender) const {
#if DEBUG
    return _action.initialTarget(sender);
#else
    return nil;
#endif
  }
};

void _CKTypedComponentDebugCheckComponentScope(const CKComponentScope &scope, SEL selector, const std::vector<const char *> &typeEncodings) noexcept;

void _CKTypedComponentDebugCheckTargetSelector(id target, SEL selector, const std::vector<const char *> &typeEncodings) noexcept;

NSString *_CKComponentResponderChainDebugResponderChain(id responder) noexcept;

#pragma mark - Sending

NSInvocation *CKComponentActionSendResponderInvocationPrepare(SEL selector, id target, CKComponent *sender) noexcept;

template<typename... T>
static void CKComponentActionSendResponderChain(SEL selector, id target, CKComponent *sender, T... args) {
  NSInvocation *invocation = CKComponentActionSendResponderInvocationPrepare(selector, target, sender);
  CKCAssert(invocation.methodSignature.numberOfArguments <= sizeof...(args) + 3, @"Target invocation contains too many arguments: sender: %@ | SEL: %@ | target: %@", sender, NSStringFromSelector(selector), invocation.target);
  // We use a recursive argument unpack to unwrap the variadic arguments in-order on the invocation in a type-safe
  // manner.
  CKConfigureInvocationWithArguments(invocation, 3, args...);
  // NSInvocation does not by default retain its target or object arguments. We have to manually call this to ensure
  // that these arguments and target are not deallocated through the scope of the invocation.
  [invocation retainArguments];
  [invocation invoke];
}
