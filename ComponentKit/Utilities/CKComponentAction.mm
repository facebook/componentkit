/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentAction.h"

#import <unordered_map>
#import <vector>
#import <array>
#import <objc/runtime.h>

#import "CKAssert.h"
#import "CKComponent+UIView.h"
#import "CKComponent.h"
#import "CKComponentInternal.h"
#import "CKInternalHelpers.h"
#import "CKMutex.h"

void CKActionTypeVectorBuild(std::vector<const char *> &typeVector, const CKActionTypelist<> &list) noexcept { }
void CKConfigureInvocationWithArguments(NSInvocation *invocation, NSInteger index) noexcept { }

#pragma mark - CKActionBase

bool CKActionBase::operator==(const CKActionBase& rhs) const
{
  return (_variant == rhs._variant
          && CKObjectIsEqual(_target, rhs._target)
          // If we are using a scoped action, we are only concerned that the selector and the
          // scoped responder match. Since the scoped responder is abstracted away to the block
          // within in the pair, we provide a identifier to quickly verify the scoped responders are the same.
          && _scopeIdentifierAndResponderGenerator.first == rhs._scopeIdentifierAndResponderGenerator.first
          && _selector == rhs._selector
          && _block == rhs._block);
}

CKComponentActionSendBehavior CKActionBase::defaultBehavior() const
{
  return (_variant == CKActionVariant::RawSelector
          ? CKComponentActionSendBehaviorStartAtSenderNextResponder
          : CKComponentActionSendBehaviorStartAtSender);
};

id CKActionBase::initialTarget(CKComponent *sender) const
{
  switch (_variant) {
    case CKActionVariant::RawSelector:
      return sender;
    case CKActionVariant::TargetSelector:
      return _target;
    case CKActionVariant::Responder:
      return _scopeIdentifierAndResponderGenerator.second ? _scopeIdentifierAndResponderGenerator.second() : nil;
    case CKActionVariant::Block:
      CKCFailAssert(@"Should not be asking for target for block action.");
      return nil;
  }
}

CKActionBase::CKActionBase() noexcept : _target(nil), _scopeIdentifierAndResponderGenerator({}), _block(NULL), _variant(CKActionVariant::RawSelector), _selector(nullptr) {}

CKActionBase::CKActionBase(id target, SEL selector) noexcept : _target(target), _scopeIdentifierAndResponderGenerator({}), _block(NULL), _variant(CKActionVariant::TargetSelector), _selector(selector) {};

CKActionBase::CKActionBase(const CKComponentScope &scope, SEL selector) noexcept : _target(nil), _block(NULL), _variant(CKActionVariant::Responder), _selector(selector)
{
  const auto handle = scope.scopeHandle();
  CKCAssert(handle, @"You are creating an action that will not fire because you have an invalid scope handle.");

  const auto scopedResponder = handle.scopedResponder;
  const auto responderKey = [scopedResponder keyForHandle:handle];
  _scopeIdentifierAndResponderGenerator = {
    [handle globalIdentifier],
    ^id(void) {

      /** 
       At one point in the history of ComponentKit, it was possible for a CKScopeResponder to
       return a "stale" target for an action. This was often caused by retain cycles, or,
       "old" component hierarchies with prolonged lifecycles.
       
       To prevent this from happening in the future we now provide a key which gives the 
       scopeResponder the wisdom to ignore older generations.
       */
      return [scopedResponder responderForKey:responderKey];
    }
  };
};

CKActionBase::CKActionBase(SEL selector) noexcept : _target(nil), _scopeIdentifierAndResponderGenerator({}), _block(NULL), _variant(CKActionVariant::RawSelector), _selector(selector) {};

CKActionBase::CKActionBase(dispatch_block_t block) noexcept : _target(nil), _scopeIdentifierAndResponderGenerator({}), _block(block), _variant(CKActionVariant::Block), _selector(NULL) {};

CKActionBase::operator bool() const noexcept { return _selector != NULL || _block != NULL || _scopeIdentifierAndResponderGenerator.second != nil; };

SEL CKActionBase::selector() const noexcept { return _selector; };

std::string CKActionBase::identifier() const noexcept
{
  switch (_variant) {
    case CKActionVariant::RawSelector:
      return std::string(sel_getName(_selector)) + "-Selector";
    case CKActionVariant::TargetSelector:
      return std::string(sel_getName(_selector)) + "-TargetSelector-" + std::to_string((long)_target);
    case CKActionVariant::Responder:
      return std::string(sel_getName(_selector)) + "-Responder-" + std::to_string(_scopeIdentifierAndResponderGenerator.first);
    case CKActionVariant::Block:
      return std::string(sel_getName(_selector)) + "-Block-" + std::to_string((long)_block);
  }
}

dispatch_block_t CKActionBase::block() const noexcept { return _block; };

#pragma mark - Sending

CKActionInfo CKActionFind(SEL selector, id target) noexcept
{
  // If we don't have a selector or target, we bail early.
  if (!selector || !target) {
    return {};
  }

  id responder = ([target respondsToSelector:@selector(targetForAction:withSender:)]
                  ? [target targetForAction:selector withSender:target]
                  : target);

  IMP imp = [responder methodForSelector:selector];
  while (!imp) {
    // From https://www.mikeash.com/pyblog/friday-qa-2009-03-27-objective-c-message-forwarding.html
    // 1. Lazy method resolution
    if ( [[responder class] resolveInstanceMethod:selector]) {
      imp = [responder methodForSelector:selector];
      // The responder resolved its instance method, we now have a valid responder/signature
      break;
    }

    // 2. Fast-forwarding path
    id forwardingTarget = [responder forwardingTargetForSelector:selector];
    if (!forwardingTarget || forwardingTarget == responder) {
      // Bail, the object they're asking us to message will just crash if the method is invoked on them
      CKCFailAssert(@"Forwarding target failed for action:%@ %@", target, NSStringFromSelector(selector));
      return {};
    }
    
    responder = forwardingTarget;
    imp = [responder methodForSelector:selector];
  }
  
  CKCAssert(imp != nil,
            @"IMP not found for selector => SEL: %@ | target: %@",
            NSStringFromSelector(selector), [target class]);
  
  return {imp, responder};
}

#pragma mark - Legacy Send Functions

void CKComponentActionSend(const CKUntypedComponentAction &action, CKComponent *sender)
{
  action.send(sender);
}

void CKComponentActionSend(const CKUntypedComponentAction &action, CKComponent *sender, CKComponentActionSendBehavior behavior)
{
  action.send(sender, behavior);
}

void CKComponentActionSend(const CKAction<id> &action, CKComponent *sender, id context)
{
  action.send(sender, action.defaultBehavior(), context);
}

void CKComponentActionSend(const CKAction<id> &action, CKComponent *sender, id context, CKComponentActionSendBehavior behavior)
{
  action.send(sender, behavior, context);
}

#pragma mark - Control Actions

@interface CKComponentActionControlForwarder : NSObject
- (instancetype)initWithControlEvents:(UIControlEvents)controlEvents;
- (void)handleControlEventFromSender:(UIControl *)sender withEvent:(UIEvent *)event;
@end

/** Stashed as an associated object on UIControl instances; contains a list of CKComponentActions. */
@interface CKComponentActionList : NSObject
{
  @public
  std::unordered_map<UIControlEvents, std::vector<CKAction<UIEvent *>>> _actions;
  std::unordered_set<UIControlEvents> _registeredForwarders;
}
@end
@implementation CKComponentActionList @end

static void *ck_actionListKey = &ck_actionListKey;

typedef std::unordered_map<UIControlEvents, CKComponentActionControlForwarder *> ForwarderMap;

CKComponentViewAttributeValue CKComponentActionAttribute(const CKAction<UIEvent *> action,
                                                         UIControlEvents controlEvents) noexcept
{
  if (!action) {
    return {
      {"CKComponentActionAttribute-no-op", ^(UIControl *control, id value) {}, ^(UIControl *control, id value) {}},
      // Use a bogus value for the attribute's "value". All the information is encoded in the attribute itself.
      @YES
    };
  }

  static ForwarderMap *map = new ForwarderMap(); // access on main thread only; never destructed to avoid static destruction fiasco
  return {
    {
      std::string("CKComponentActionAttribute-") + action.identifier() + "-" + std::to_string(controlEvents),
      ^(UIControl *control, id value){
        CKComponentActionList *list = objc_getAssociatedObject(control, ck_actionListKey);
        if (list == nil) {
          list = [CKComponentActionList new];
          objc_setAssociatedObject(control, ck_actionListKey, list, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (list->_registeredForwarders.insert(controlEvents).second) {
          // Since this is the first time we've seen this {control, events} pair, add a Forwarder as a target.
          const auto it = map->find(controlEvents);
          CKComponentActionControlForwarder *const forwarder =
          (it == map->end())
          ? map->insert({controlEvents, [[CKComponentActionControlForwarder alloc] initWithControlEvents:controlEvents]}).first->second
          : it->second;
          [control addTarget:forwarder
                      action:@selector(handleControlEventFromSender:withEvent:)
            forControlEvents:controlEvents];
        }
        list->_actions[controlEvents].push_back(action);
      },
      ^(UIControl *control, id value){
        CKComponentActionList *const list = objc_getAssociatedObject(control, ck_actionListKey);
        CKCAssertNotNil(list, @"Unapplicator should always find an action list installed by applicator");
        auto &actionList = list->_actions[controlEvents];
        actionList.erase(std::find(actionList.begin(), actionList.end(), action));
        // Don't bother unsetting the action list or removing the forwarder as a target; both are harmless.
      }
    },
    // Use a bogus value for the attribute's "value". All the information is encoded in the attribute itself.
    @YES
  };
}

@implementation CKComponentActionControlForwarder
{
  UIControlEvents _controlEvents;
}

- (instancetype)initWithControlEvents:(UIControlEvents)controlEvents
{
  if (self = [super init]) {
    _controlEvents = controlEvents;
  }
  return self;
}

- (void)handleControlEventFromSender:(UIControl *)sender withEvent:(UIEvent *)event
{
  CKComponentActionList *const list = objc_getAssociatedObject(sender, ck_actionListKey);
  CKCAssertNotNil(list, @"Forwarder should always find an action list installed by applicator");
  // Protect against mutation-during-enumeration by copying the list of actions to send:
  const std::vector<CKAction<UIEvent *>> copiedActions = list->_actions[_controlEvents];
  CKComponent *const sendingComponent = sender.ck_component;
  for (const auto &action : copiedActions) {
    // If the action can be handled by the sender itself, send it there instead of looking up the chain.
    action.send(sendingComponent, CKComponentActionSendBehaviorStartAtSender, event);
  }
}

@end

#pragma mark - Debug Helpers

std::unordered_map<UIControlEvents, std::vector<CKAction<UIEvent *>>> _CKComponentDebugControlActionsForComponent(CKComponent *const component)
{
#if DEBUG
  CKComponentActionList *const list = objc_getAssociatedObject(component.viewContext.view, ck_actionListKey);
  if (list == nil) {
    return {};
  }
  return list->_actions;
#else
  return {};
#endif
}

#if DEBUG
static void checkMethodSignatureAgainstTypeEncodings(SEL selector, NSMethodSignature *signature, const std::vector<const char *> &typeEncodings)
{
  if (selector == NULL) {
    return;
  }

  CKCAssert(typeEncodings.size() + 3 >= signature.numberOfArguments, @"Expected action method %@ to take less than %llu arguments, but it suppoorts %llu", NSStringFromSelector(selector), (unsigned long long)typeEncodings.size(), (unsigned long long)signature.numberOfArguments - 3);

  CKCAssert(signature.methodReturnLength == 0, @"Component action methods should not have any return value. Any objects returned from this method will be leaked.");

  for (int i = 0; i + 3 < signature.numberOfArguments && i < typeEncodings.size(); i++) {
    const char *methodEncoding = [signature getArgumentTypeAtIndex:i + 3];
    const char *typeEncoding = typeEncodings[i];

    CKCAssert(methodEncoding == NULL || typeEncoding == NULL || strcmp(methodEncoding, typeEncoding) == 0, @"Implementation of %@ does not match expected types.\nExpected type %s, got %s", NSStringFromSelector(selector), typeEncoding, methodEncoding);
  }
    
  if (signature.numberOfArguments >= 3) {
    const char *methodEncoding = [signature getArgumentTypeAtIndex:2];
    CKCAssert(methodEncoding == NULL || strcmp(methodEncoding, "@") == 0, @"Implementation of %@ does not match expected types.\nExpected type @, got %s for first parameter", NSStringFromSelector(selector), methodEncoding);
  }
}
#endif

void _CKTypedComponentDebugCheckComponentScope(const CKComponentScope &scope, SEL selector, const std::vector<const char *> &typeEncodings) noexcept
{
#if DEBUG
  CKComponentScopeHandle *const scopeHandle = scope.scopeHandle();

  // In DEBUG mode, we want to do the minimum of type-checking for the action that's possible in Objective-C. We
  // can't do exact type checking, but we can ensure that you're passing the right type of primitives to the right
  // argument indices.
  const Class klass = scopeHandle.componentClass;
  // We allow component actions to be implemented either in the component, or its controller.
  const Class controllerKlass = [klass controllerClass];
  CKCAssert(selector == NULL || [klass instancesRespondToSelector:selector] || [controllerKlass instancesRespondToSelector:selector], @"Target does not respond to selector for component action. -[%@ %@]", klass, NSStringFromSelector(selector));

  NSMethodSignature *signature = [klass instanceMethodSignatureForSelector:selector] ?: [controllerKlass instanceMethodSignatureForSelector:selector];

  checkMethodSignatureAgainstTypeEncodings(selector, signature, typeEncodings);
#endif
}

void _CKTypedComponentDebugCheckTargetSelector(id target, SEL selector, const std::vector<const char *> &typeEncodings) noexcept
{
#if DEBUG
  // In DEBUG mode, we want to do the minimum of type-checking for the action that's possible in Objective-C. We
  // can't do exact type checking, but we can ensure that you're passing the right type of primitives to the right
  // argument indices.
  CKCAssert(selector == NULL || [target respondsToSelector:selector], @"Target does not respond to selector for component action. -[%@ %@]", [target class], NSStringFromSelector(selector));

  NSMethodSignature *signature = [target methodSignatureForSelector:selector];

  checkMethodSignatureAgainstTypeEncodings(selector, signature, typeEncodings);
#endif
}

// This method returns a friendly-print of a responder chain. Used for debug purposes.
NSString *_CKComponentResponderChainDebugResponderChain(id responder) noexcept {
  return (responder
          ? [NSString stringWithFormat:@"%@ -> %@", responder, _CKComponentResponderChainDebugResponderChain([responder nextResponder])]
          : @"nil");
}

#pragma mark - Accessibility Actions

@interface CKComponentAccessibilityCustomAction : UIAccessibilityCustomAction
- (instancetype)initWithName:(NSString *)name action:(const CKUntypedComponentAction &)action view:(UIView *)view;
@end

@implementation CKComponentAccessibilityCustomAction
{
  UIView *_ck_view;
  CKUntypedComponentAction _ck_action;
}

- (instancetype)initWithName:(NSString *)name action:(const CKUntypedComponentAction &)action view:(UIView *)view
{
  if (self = [super initWithName:name target:self selector:@selector(ck_send)]) {
    _ck_view = view;
    _ck_action = action;
  }
  return self;
}

- (BOOL)ck_send
{
  _ck_action.send(_ck_view.ck_component, CKComponentActionSendBehaviorStartAtSender);
  return YES;
}

@end

CKComponentViewAttributeValue CKComponentAccessibilityCustomActionsAttribute(const std::vector<std::pair<NSString *, CKUntypedComponentAction>> &passedActions) noexcept
{
  auto const actions = passedActions;
  return {
    {
      std::string(sel_getName(@selector(setAccessibilityCustomActions:))),
      ^(UIView *view, id value){
        NSMutableArray<CKComponentAccessibilityCustomAction *> *accessibilityCustomActions = [NSMutableArray new];
        for (auto const& action : actions) {
          if (action.first && action.second) {
            [accessibilityCustomActions addObject:[[CKComponentAccessibilityCustomAction alloc] initWithName:action.first action:action.second view:view]];
          }
        }
        view.accessibilityCustomActions = accessibilityCustomActions;
      },
      ^(UIView *view, id value){
        view.accessibilityCustomActions = nil;
      }
    },
    // Use a bogus value for the attribute's "value". All the information is encoded in the attribute itself.
    @YES
  };
}

#pragma mark - Template instantiations

template class CKAction<>;
template class CKAction<id>;
