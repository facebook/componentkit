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

using namespace CK::Component;

static pthread_key_t kCKComponentLayoutContextThreadKey;

struct ThreadKeyInitializer {
  static void destroyStack(LayoutContextStack *p) { delete p; }
  ThreadKeyInitializer() { pthread_key_create(&kCKComponentLayoutContextThreadKey, (void (*)(void*))destroyStack); }
};

static LayoutContextStack &componentStack()
{
  static ThreadKeyInitializer threadKey;
  LayoutContextStack *contexts = static_cast<LayoutContextStack *>(pthread_getspecific(kCKComponentLayoutContextThreadKey));
  if (!contexts) {
    contexts = new LayoutContextStack;
    pthread_setspecific(kCKComponentLayoutContextThreadKey, contexts);
  }
  return *contexts;
}

static void removeComponentStackForThisThread()
{
  LayoutContextStack *contexts = static_cast<LayoutContextStack *>(pthread_getspecific(kCKComponentLayoutContextThreadKey));
  ThreadKeyInitializer::destroyStack(contexts);
  pthread_setspecific(kCKComponentLayoutContextThreadKey, nullptr);
}

LayoutContext::LayoutContext(CKComponent *c, CKSizeRange r) : component(c), sizeRange(r)
{
  auto &stack = componentStack();
  stack.push_back(this);
}

LayoutContext::~LayoutContext()
{
  auto &stack = componentStack();
  CKCAssert(stack.back() == this,
            @"Last component layout context %@ is not %@", stack.back()->component, component);
  stack.pop_back();
  if (stack.empty()) {
    removeComponentStackForThisThread();
  }
}

const CK::Component::LayoutContextStack &LayoutContext::currentStack()
{
  return componentStack();
}

NSString *LayoutContext::currentStackDescription()
{
  const auto &stack = componentStack();
  NSMutableString *s = [NSMutableString string];
  NSUInteger idx = 0;
  for (CK::Component::LayoutContext *c : stack) {
    if (idx != 0) {
      [s appendString:@"\n"];
    }
    [s appendString:[@"" stringByPaddingToLength:idx withString:@" " startingAtIndex:0]];
    [s appendString:NSStringFromClass([c->component class])];
    [s appendString:@": "];
    [s appendString:c->sizeRange.description()];
    idx++;
  }
  return s;
}
