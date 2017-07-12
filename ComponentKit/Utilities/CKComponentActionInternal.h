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

#pragma mark - Action Base

/** A base-class for typed components that doesn't use templates to avoid template bloat. */
class CKTypedComponentActionBase {
  protected:
  
  /**
   We support several different types of action variants. You don't need to use this value anywhere, it's set for you
   by whatever initializer you end up using.
   */
  enum class CKTypedComponentActionVariant {
    RawSelector,
    TargetSelector,
    Responder,
    Block
  };

  CKTypedComponentActionBase() noexcept;
  CKTypedComponentActionBase(id target, SEL selector) noexcept;

  CKTypedComponentActionBase(const CKComponentScope &scope, SEL selector) noexcept;

  /** Legacy constructor for raw selector actions. Traverse up the mount responder chain. */
  CKTypedComponentActionBase(SEL selector) noexcept;
  
  CKTypedComponentActionBase(dispatch_block_t block) noexcept;

  ~CKTypedComponentActionBase() {};

  id initialTarget(CKComponent *sender) const;
  CKComponentActionSendBehavior defaultBehavior() const;

  bool operator==(const CKTypedComponentActionBase& rhs) const;

  // Destroying this field calls objc_destroyWeak. Since this is the only field
  // that runs code on destruction, making this field the first field of this
  // object saves an offset calculation instruction in the destructor.
  __weak id _target;
  std::pair<CKScopedResponderUniqueIdentifier, CKResponderGenerationBlock> _scopeIdentifierAndResponderGenerator;
  dispatch_block_t _block;
  CKTypedComponentActionVariant _variant;
  SEL _selector;

public:
  explicit operator bool() const noexcept;
  bool isEqual(const CKTypedComponentActionBase &rhs) const noexcept {
    return *this == rhs;
  }
  SEL selector() const noexcept;
  dispatch_block_t block() const noexcept;
  std::string identifier() const noexcept;
};

#pragma mark - Typed Helpers

template <typename... Ts> struct CKTypedComponentActionTypelist { };

/** Base case, recursion should stop here. */
void CKTypedComponentActionTypeVectorBuild(std::vector<const char *> &typeVector, const CKTypedComponentActionTypelist<> &list) noexcept;

/**
 Recursion through variadic argument type unpacking. This allows us to build a vector of encoded const char * before
 any actual arguments have been provided. All of this is done at compile-time.
 */
template<typename T, typename... Ts>
void CKTypedComponentActionTypeVectorBuild(std::vector<const char *> &typeVector, const CKTypedComponentActionTypelist<T, Ts...> &list) noexcept
{
  typeVector.push_back(@encode(T));
  CKTypedComponentActionTypeVectorBuild(typeVector, CKTypedComponentActionTypelist<Ts...>{});
}

#pragma mark - Debug Helpers

void _CKTypedComponentDebugCheckComponentScope(const CKComponentScope &scope, SEL selector, const std::vector<const char *> &typeEncodings) noexcept;

void _CKTypedComponentDebugCheckTargetSelector(id target, SEL selector, const std::vector<const char *> &typeEncodings) noexcept;

NSString *_CKComponentResponderChainDebugResponderChain(id responder) noexcept;

#pragma mark - Sending

struct _CKComponentActionInvocation {
  IMP imp;
  id target;
};

_CKComponentActionInvocation _CKComponentActionSendResponderInvocationPrepare(SEL selector, id target, CKComponent *sender) noexcept;

template<typename... T>
static void CKComponentActionSendResponderChain(SEL selector, id target, CKComponent *sender, T... args) {
  _CKComponentActionInvocation invocation =
  _CKComponentActionSendResponderInvocationPrepare(selector, target, sender);

  if (!invocation.target || !invocation.imp) {
    return;
  }

  void (*imp)(id, SEL, id, T...) = (void (*)(id, SEL, id, T...))invocation.imp;

  imp(invocation.target, selector, sender, args...);
}
