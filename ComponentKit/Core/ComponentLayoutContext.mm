/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "ComponentLayoutContext.h"

#import <pthread.h>
#import <stack>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKStatelessComponent.h>

using namespace CK::Component;

static pthread_key_t kCKComponentLayoutContextThreadKey;

struct ThreadKeyInitializer {
  static void destroyStack(LayoutContextValue *p) { delete p; }
  ThreadKeyInitializer() { pthread_key_create(&kCKComponentLayoutContextThreadKey, (void (*)(void*))destroyStack); }
};

static LayoutContextValue &componentValue(id<CKSystraceListener> listener = nil)
{
  static ThreadKeyInitializer threadKey;
  LayoutContextValue *contexts = static_cast<LayoutContextValue *>(pthread_getspecific(kCKComponentLayoutContextThreadKey));
  if (!contexts) {
    contexts = new LayoutContextValue;
    if (listener) {
      contexts->systraceListener = listener;
    }
    pthread_setspecific(kCKComponentLayoutContextThreadKey, contexts);
  }
  return *contexts;
}

static void removeComponentStackForThisThread()
{
  LayoutContextValue *contexts = static_cast<LayoutContextValue *>(pthread_getspecific(kCKComponentLayoutContextThreadKey));
  ThreadKeyInitializer::destroyStack(contexts);
  pthread_setspecific(kCKComponentLayoutContextThreadKey, nullptr);
}

LayoutContext::LayoutContext(CKComponent *c, CKSizeRange r) : component(c), sizeRange(r)
{
  auto &value = componentValue();
  systraceListener = value.systraceListener;
  value.stack.push_back(this);
}

LayoutContext::~LayoutContext()
{
  auto &stack = componentValue().stack;
  CKCAssert(stack.back() == this,
            @"Last component layout context %@ is not %@", stack.back()->component, component);
  stack.pop_back();
  if (stack.empty()) {
    removeComponentStackForThisThread();
  }
}

const CK::Component::LayoutContextStack &LayoutContext::currentStack()
{
  return componentValue().stack;
}

static auto componentClassString(CKComponent *component) -> NSString * {
  if ([component isKindOfClass: [CKStatelessComponent class]]) {
    return [[(CKStatelessComponent *)component identifier] stringByAppendingString:@" (CKStatelessComponent)"];
  } else {
    return NSStringFromClass([component class]);
  }
}

NSString *LayoutContext::currentStackDescription()
{
  const auto &stack = componentValue().stack;
  NSMutableString *s = [NSMutableString string];
  NSUInteger idx = 0;
  for (CK::Component::LayoutContext *c : stack) {
    if (idx != 0) {
      [s appendString:@"\n"];
    }
    [s appendString:[@"" stringByPaddingToLength:idx withString:@" " startingAtIndex:0]];
    [s appendString:componentClassString(c->component)];
    [s appendString:@": "];
    [s appendString:c->sizeRange.description()];
    idx++;
  }
  return s;
}

NSString *LayoutContext::currentRootComponentClassName()
{
  const auto &stack = componentValue().stack;
  return stack.empty() ? @"" : componentClassString(stack[0]->component);
}

LayoutSystraceContext::LayoutSystraceContext(id<CKSystraceListener> listener) {
  if (listener) {
    componentValue(listener);
  }
}
