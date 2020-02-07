/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAction.h"

#import <unordered_map>
#import <vector>
#import <array>

#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKAssociatedObject.h>
#import <ComponentKit/CKMutex.h>

#import "CKComponent+UIView.h"
#import "CKComponent.h"
#import "CKComponentInternal.h"

void CKActionTypeVectorBuild(std::vector<const char *> &typeVector, const CKActionTypelist<> &list) noexcept { }
void CKConfigureInvocationWithArguments(NSInvocation *invocation, NSInteger index) noexcept { }

static auto createScopeIdentifierAndResponderGenerator(CKComponentScopeHandle *handle,
                                                       SEL selector) ->
std::pair<CKScopedResponderUniqueIdentifier, CKResponderGenerationBlock>
{
  const auto scopedResponder = handle.scopedResponder;
  const auto responderKey = [scopedResponder keyForHandle:handle];
  return {
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
}

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

CKActionSendBehavior CKActionBase::defaultBehavior() const
{
  return (_variant == CKActionVariant::RawSelector
          ? CKActionSendBehaviorStartAtSenderNextResponder
          : CKActionSendBehaviorStartAtSender);
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
  CKCAssertNotNil(handle, @"You are creating an action that will not fire because you have an invalid scope handle.");
  _scopeIdentifierAndResponderGenerator = createScopeIdentifierAndResponderGenerator(handle, selector);
}

CKActionBase::CKActionBase(SEL selector, id<CKRenderComponentProtocol> component) noexcept : _target(nil), _block(NULL), _variant(CKActionVariant::Responder), _selector(selector)
{
  auto const handle = component.scopeHandle;
  CKCAssertNotNil(handle, @"You are creating an action that will not fire because you have an invalid scope handle.");
  _scopeIdentifierAndResponderGenerator = createScopeIdentifierAndResponderGenerator(handle, selector);
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
  CKCAssert(![responder isProxy],
            @"NSProxy can't be a responder for target-selector CKAction. Please use a block action instead.");
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
      CKCFailAssertWithCategory(NSStringFromSelector(selector),
                                @"Forwarding target failed for action: %@ %@",
                                NSStringFromSelector(selector),
                                target);
      return {};
    }

    responder = forwardingTarget;
    CKCAssert(![responder isProxy],
              @"NSProxy can't be a responder for target-selector CKAction. Please use a block action instead.");
    imp = [responder methodForSelector:selector];
  }

  CKCAssert(imp != nil,
            @"IMP not found for selector => SEL: %@ | target: %@",
            NSStringFromSelector(selector), [target class]);

  return {imp, responder};
}

#pragma mark - Legacy Send Functions

void CKActionSend(const CKAction<> &action, CKComponent *sender)
{
  action.send(sender);
}

void CKActionSend(const CKAction<> &action, CKComponent *sender, CKActionSendBehavior behavior)
{
  action.send(sender, behavior);
}

void CKActionSend(const CKAction<id> &action, CKComponent *sender, id context)
{
  action.send(sender, action.defaultBehavior(), context);
}

void CKActionSend(const CKAction<id> &action, CKComponent *sender, id context, CKActionSendBehavior behavior)
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
        CKComponentActionList *list = CKGetAssociatedObject_MainThreadAffined(control, ck_actionListKey);
        if (list == nil) {
          list = [CKComponentActionList new];
          CKSetAssociatedObject_MainThreadAffined(control, ck_actionListKey, list);
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
        CKComponentActionList *const list = CKGetAssociatedObject_MainThreadAffined(control, ck_actionListKey);
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
  CKComponentActionList *const list = CKGetAssociatedObject_MainThreadAffined(sender, ck_actionListKey);
  CKCAssertNotNil(list, @"Forwarder should always find an action list installed by applicator");
  // Protect against mutation-during-enumeration by copying the list of actions to send:
  const std::vector<CKAction<UIEvent *>> copiedActions = list->_actions[_controlEvents];
  CKComponent *const sendingComponent = CKMountedComponentForView(sender);
  for (const auto &action : copiedActions) {
    // If the action can be handled by the sender itself, send it there instead of looking up the chain.
    action.send(sendingComponent, CKActionSendBehaviorStartAtSender, event);
  }
}

@end

#pragma mark - Debug Helpers

std::unordered_map<UIControlEvents, std::vector<CKAction<UIEvent *>>> _CKComponentDebugControlActionsForComponent(CKComponent *const component)
{
#if DEBUG
  CKComponentActionList *const list = CKGetAssociatedObject_MainThreadAffined(component.viewContext.view, ck_actionListKey);
  if (list == nil) {
    return {};
  }
  return list->_actions;
#else
  return {};
#endif
}

BOOL checkMethodSignatureAgainstTypeEncodings(SEL selector, Method method, const std::vector<const char *> &typeEncodings)
{
  if (selector == NULL) {
    return NO;
  }

  if (typeEncodings.size() + 3 < method_getNumberOfArguments(method)) {
    CKCFailAssert(@"Expected action method %@ to take less than %llu arguments, but it supports %llu", NSStringFromSelector(selector), (unsigned long long)typeEncodings.size(), (unsigned long long)method_getNumberOfArguments(method) - 3);
    return NO;
  }

  char *return_type = method_copyReturnType(method);
  if (return_type == NULL) {
    return NO;
  }
  const bool has_return_type = strcmp(return_type, "v") != 0; // "v" is void
  free(return_type);

  if (has_return_type) {
    CKCFailAssert(@"Component action methods should not have any return value. Any objects returned from this method will be leaked.");
    return NO;
  }

  // Skipping self, _cmd, and sender (the component).
  for (int i = 0; i + 3 < method_getNumberOfArguments(method) && i < typeEncodings.size(); i++) {
    char *cp_argType = method_copyArgumentType(method, i + 3); // freed later - DON'T early exit!
    char *methodEncoding = cp_argType; // a pointer we can move around
    const char *typeEncoding = typeEncodings[i];

    // Type Encoding: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html

    // ref types get '^' prefixed to them. Since C++ would implicitly
    // use pass-by-ref or pass-by-value based the called function, we
    // treat a mismatch between ref & copy as valid.
    if (methodEncoding != NULL && *methodEncoding == '^') {
      methodEncoding++;
    }
    if (typeEncoding != NULL && *typeEncoding == '^') {
      typeEncoding++;
    }

    BOOL doEncodingsMatch = NO;
    if (methodEncoding == NULL || typeEncoding == NULL) {
      // nothing to compare
      doEncodingsMatch = YES;
    } else if (*methodEncoding == '{' && *typeEncoding == '{') {
      // types are structures. Due to an issue with c++ types not always being
      // encoded the same even thought they are basically the same, we only
      // compare the structure name. (see T23131874)
      const char *nameEnd = strchr(methodEncoding, '=');
      const size_t nameSize = nameEnd - methodEncoding;
      doEncodingsMatch =
      (nameEnd
       && strlen(typeEncoding) >= nameSize
       && strncmp(methodEncoding, typeEncoding, nameSize) == 0);
    } else {
      doEncodingsMatch = strcmp(methodEncoding, typeEncoding) == 0;
    }

    NSString *safe_methodEncoding = [NSString stringWithFormat:@"%s", methodEncoding];
    free(cp_argType);

    if (!doEncodingsMatch) {
      CKCFailAssert(@"Implementation of %@ does not match expected types.\nExpected type %s, got %@", NSStringFromSelector(selector), typeEncoding, safe_methodEncoding);
      return NO;
    }

    safe_methodEncoding = nil; // avoids -Wunused-variable
  }

  if (method_getNumberOfArguments(method) >= 3) {
    char *const unasfe_methodEncoding = method_copyArgumentType(method, 2);
    NSString *methodEncoding = [NSString stringWithFormat:@"%s", unasfe_methodEncoding ?: ""];
    free(unasfe_methodEncoding);

    if (methodEncoding != nil && [methodEncoding isEqualToString:@"@"] == NO) {
      CKCFailAssert(@"Sender of %@ is not an object.\nGot %@ instead. Please add the component as the first argument when sending an action", NSStringFromSelector(selector), methodEncoding);
      return NO;
    }
  }

  return YES;
}

#if DEBUG
void _CKTypedComponentDebugCheckComponentScope(const CKComponentScope &scope, SEL selector, const std::vector<const char *> &typeEncodings) noexcept
{
  _CKTypedComponentDebugCheckComponentScopeHandle(scope.scopeHandle(), selector, typeEncodings);
}

void _CKTypedComponentDebugCheckComponentScopeHandle(CKComponentScopeHandle *handle, SEL selector, const std::vector<const char *> &typeEncodings) noexcept
{
  // In DEBUG mode, we want to do the minimum of type-checking for the action that's possible in Objective-C. We
  // can't do exact type checking, but we can ensure that you're passing the right type of primitives to the right
  // argument indices.
  const Class klass = handle.componentClass;

  _CKTypedComponentDebugCheckComponent(klass, selector, typeEncodings);
}

void _CKTypedComponentDebugCheckTargetSelector(id target, SEL selector, const std::vector<const char *> &typeEncodings) noexcept
{
  // In DEBUG mode, we want to do the minimum of type-checking for the action that's possible in Objective-C. We
  // can't do exact type checking, but we can ensure that you're passing the right type of primitives to the right
  // argument indices.
  if (selector == NULL) {
    return;
  }

  // If the target is `Class<CKComponentProtocol>`, we pass it to the `_CKTypedComponentDebugCheckComponent` function.
  if ([[target class] respondsToSelector:@selector(controllerClass)]) {
    _CKTypedComponentDebugCheckComponent([target class], selector, typeEncodings);
    return;
  }

  CKCAssert([target respondsToSelector:selector], @"Target does not respond to selector for component action. -[%@ %@]", [target class], NSStringFromSelector(selector));

  Method method = class_getInstanceMethod([target class], selector);
  checkMethodSignatureAgainstTypeEncodings(selector, method, typeEncodings);
}

void _CKTypedComponentDebugCheckComponent(Class<CKComponentProtocol> klass, SEL selector, const std::vector<const char *> &typeEncodings) noexcept
{
  // We allow component actions to be implemented either in the component, or its controller.
  const Class componentKlass = klass;
  const Class controllerKlass = [klass controllerClass];
  if (selector == NULL) {
    return;
  }
  CKCAssert([componentKlass instancesRespondToSelector:selector] || [controllerKlass instancesRespondToSelector:selector], @"Target does not respond to selector for component action. -[%@ %@]", componentKlass, NSStringFromSelector(selector));

  // Type encoding with NSMethodSignatue isn't working well for C++, so we use class_getInstanceMethod()
  Method method = class_getInstanceMethod(componentKlass, selector) ?: class_getInstanceMethod(controllerKlass, selector);
  checkMethodSignatureAgainstTypeEncodings(selector, method, typeEncodings);
}
#endif

// This method returns a friendly-print of a responder chain. Used for debug purposes.
NSString *_CKComponentResponderChainDebugResponderChain(id responder) noexcept {
  return (responder
          ? [NSString stringWithFormat:@"%@ -> %@", responder, _CKComponentResponderChainDebugResponderChain([responder nextResponder])]
          : @"nil");
}

#pragma mark - Accessibility Actions

@interface CKComponentAccessibilityCustomAction : UIAccessibilityCustomAction
- (instancetype)initWithName:(NSString *)name action:(const CKAction<> &)action view:(UIView *)view;
@end

@implementation CKComponentAccessibilityCustomAction
{
  UIView *_ck_view;
  CKAction<> _ck_action;
}

- (instancetype)initWithName:(NSString *)name action:(const CKAction<> &)action view:(UIView *)view
{
  if (self = [super initWithName:name target:self selector:@selector(ck_send)]) {
    _ck_view = view;
    _ck_action = action;
  }
  return self;
}

- (BOOL)ck_send
{
  _ck_action.send(CKMountedComponentForView(_ck_view), CKActionSendBehaviorStartAtSender);
  return YES;
}

@end

CKComponentViewAttributeValue CKComponentAccessibilityCustomActionsAttribute(const std::vector<std::pair<NSString *, CKAction<>>> &passedActions) noexcept
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
