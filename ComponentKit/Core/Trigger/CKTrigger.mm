// (c) Facebook, Inc. and its affiliates. Confidential and proprietary.

#import <RenderCore/RCAssert.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKTreeNode.h>
#import <ComponentKit/CKTrigger.h>

static auto _scopedResponderAndKey(id<CKComponentProtocol> component, NSString *context) -> CKTriggerScopedResponderAndKey {

  auto const handle = component.treeNode.scopeHandle;
  auto const scopedResponder = handle.scopedResponder;
  auto const responderKey = [scopedResponder keyForHandle:handle];

  RCCAssertWithCategory(
      component != nil && handle != nil && scopedResponder != nil,
      context,
      @"Binding a trigger but something is nil (component %@, handle: %@, scopedResponder: %@)",
      component,
      handle,
      scopedResponder);

  return {scopedResponder, responderKey};
}

CKTriggerScopedResponderAndKey::CKTriggerScopedResponderAndKey(CKScopedResponder *responder, CKScopedResponderKey key) : responder(responder), key(key) {}

CKTriggerScopedResponderAndKey::CKTriggerScopedResponderAndKey(id<CKComponentProtocol> component, NSString *context) : CKTriggerScopedResponderAndKey(_scopedResponderAndKey(component, context)) {}
