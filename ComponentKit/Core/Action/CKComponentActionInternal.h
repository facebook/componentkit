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

#import <UIKit/UIKit.h>

#import <vector>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKRenderComponentProtocol.h>

#import <type_traits>

@class CKComponent;

typedef id (^CKResponderGenerationBlock)(void);
typedef NS_ENUM(NSInteger, CKActionSendBehavior) {
  /** Starts searching at the sender's next responder. Usually this is what you want to prevent infinite loops. */
  CKActionSendBehaviorStartAtSenderNextResponder,
  /** If the sender itself responds to the action, invoke the action on the sender. */
  CKActionSendBehaviorStartAtSender,
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
  CKActionBase(SEL selector, id<CKRenderComponentProtocol> component) noexcept;

  /** Legacy constructor for raw selector actions. Traverse up the mount responder chain. */
  CKActionBase(SEL selector) noexcept;

  CKActionBase(dispatch_block_t block) noexcept;

  ~CKActionBase() {};

  id initialTarget(CKComponent *sender) const;
  CKActionSendBehavior defaultBehavior() const;

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

void CKConfigureInvocationWithArguments(NSInvocation *invocation, NSInteger index) noexcept;

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

  BOOL isBlockBaseAction() const {
    return _action._variant == CKActionBase::CKActionVariant::Block;
  }
};

#if DEBUG
void _CKTypedComponentDebugCheckComponentScope(const CKComponentScope &scope, SEL selector, const std::vector<const char *> &typeEncodings) noexcept;
void _CKTypedComponentDebugCheckComponentScopeHandle(CKComponentScopeHandle *handle, SEL selector, const std::vector<const char *> &typeEncodings) noexcept;
void _CKTypedComponentDebugCheckTargetSelector(id target, SEL selector, const std::vector<const char *> &typeEncodings) noexcept;
void _CKTypedComponentDebugCheckComponent(Class<CKComponentProtocol> componentClass, SEL selector, const std::vector<const char *> &typeEncodings) noexcept;
#endif

NSString *_CKComponentResponderChainDebugResponderChain(id responder) noexcept;

#pragma mark - Sending

struct CKActionInfo {
  IMP imp;
  id responder;
};

CKActionInfo CKActionFind(SEL selector, id target) noexcept;

template<typename... T>
static void CKActionSendResponderChain(SEL selector, id target, CKComponent *sender, T... args) {

  const CKActionInfo info = CKActionFind(selector, target);
  if (!info.responder) {
    return;
  }
  CKCAssert([info.responder methodSignatureForSelector:selector].numberOfArguments <= sizeof...(args) + 3,
            @"Target invocation contains too many arguments => sender: %@ | SEL: %@ | target: %@",
            sender, NSStringFromSelector(selector), [target class]);

  // ARC assumes all IMPs return an id and will try to retain void,
  // so have to case the IMP since it returns void.
  void (*typedFunction)(id, SEL, id, T...) = (void (*)(id, SEL, id, T...))info.imp;
  typedFunction(info.responder, selector, sender, args...);
}

#endif
