/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentContextHelper.h"

#import <ComponentKit/CKAssert.h>

#import <stack>

static NSString *const kThreadDictionaryKey = @"CKComponentContext";
static NSString *const kThreadRenderSupportKey = @"CKRenderComponentContextSupport";

struct CKComponentContextStackItem {
  CKComponentContextPreviousState state;
  NSUInteger renderCounter;
};

@interface CKComponentContextValue : NSObject
{
@public
  NSMutableDictionary *_dictionary;
  std::stack<CKComponentContextStackItem> _stack;
  id<CKComponentContextDynamicLookup> _dynamicLookup;
  BOOL _enableRenderSupport;
}
@end
@implementation CKComponentContextValue @end

static CKComponentContextValue *contextValue(BOOL create)
{
  NSMutableDictionary *const threadDictionary = [[NSThread currentThread] threadDictionary];
  CKComponentContextValue *contextValue = threadDictionary[kThreadDictionaryKey];
  if (contextValue == nil && create) {
    contextValue = [CKComponentContextValue new];
    contextValue->_dictionary = [NSMutableDictionary dictionary];
    contextValue->_enableRenderSupport = [threadDictionary[kThreadRenderSupportKey] boolValue];
    threadDictionary[kThreadDictionaryKey] = contextValue;
  }
  return contextValue;
}

bool CKComponentContextContents::operator==(const CKComponentContextContents &other) const
{
  return ((other.objects == nil && objects == nil) || [other.objects isEqualToDictionary:objects])
  && other.dynamicLookup == dynamicLookup;
}

bool CKComponentContextContents::operator!=(const CKComponentContextContents &other) const
{
  return !(*this == other);
}

static void clearContextValueIfEmpty(CKComponentContextValue *const currentValue)
{
  if ([currentValue->_dictionary count] == 0 && currentValue->_stack.empty() && currentValue->_dynamicLookup == nil) {
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:kThreadDictionaryKey];
  }
}

CKComponentContextPreviousState CKComponentContextHelper::store(id key, id object)
{
  CKComponentContextValue *v = contextValue(YES);
  NSMutableDictionary *const c = v->_dictionary;
  id originalValue = c[key];
  c[key] = object;
  CKComponentContextPreviousState state = {.key = key, .originalValue = originalValue, .newValue = object};
  if (v->_enableRenderSupport) {
    v->_stack.push({.state = state, .renderCounter = 0});
  }
  return state;
}

void CKComponentContextHelper::restore(const CKComponentContextPreviousState &storeResult)
{
  // We want to create the context dictionary if it doesn't exist already, because we need to restore the original
  // value. In practice it should always exist already except for an obscure edge case; see the unit test
  // testTriplyNestedComponentContextWithNilMiddleValueCorrectlyRestoresOuterValue for an example.
  CKComponentContextValue *const v = contextValue(YES);

  // If the stack is not empty, we need to make sure that the top element's counter is `0` before deleteing this element.
  if (!v->_stack.empty()) {
    CKComponentContextStackItem &item = v->_stack.top();
    // If the counter is not '0' we keep it in the store. It will be cleaned later by `unmarkRenederComponent`.
    if (item.renderCounter > 0) {
      return;
    }
    CKCAssert(item.state.newValue == storeResult.newValue, @"Context value for %@ unexpectedly mutated from stack", storeResult.key);
    v->_stack.pop();
  }
  NSMutableDictionary *const c = v->_dictionary;
  CKCAssert(c[storeResult.key] == storeResult.newValue, @"Context value for %@ unexpectedly mutated", storeResult.key);
  c[storeResult.key] = storeResult.originalValue;
  clearContextValueIfEmpty(v);
}

static void restoreFromStack(CKComponentContextValue *const v, const CKComponentContextPreviousState &storeResult)
{
  NSMutableDictionary *const c = v->_dictionary;
  CKCAssert(c[storeResult.key] == storeResult.newValue, @"Context value for %@ unexpectedly mutated", storeResult.key);
  c[storeResult.key] = storeResult.originalValue;
}

void CKComponentContextHelper::enableRenderSupport(BOOL enable)
{
  NSMutableDictionary *const threadDictionary = [[NSThread currentThread] threadDictionary];
  threadDictionary[kThreadRenderSupportKey] = [NSNumber numberWithBool:enable];
  CKComponentContextValue *const v = contextValue(NO);
  if (v) {
    v->_enableRenderSupport = enable;
  }
}

void CKComponentContextHelper::markRenderComponent()
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v || !v->_enableRenderSupport) {
    return;
  }

  // Increment the counter of the top element.
  if (!v->_stack.empty()) {
    CKComponentContextStackItem &item = v->_stack.top();
    item.renderCounter++;
  }
}

void CKComponentContextHelper::unmarkRenderComponent()
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v || !v->_enableRenderSupport) {
    return;
  }

  if (!v->_stack.empty()) {
    // Decrement the counter of the top element.
    CKComponentContextStackItem &item = v->_stack.top();
    CKCAssert(item.renderCounter > 0, @"Top item counter is already 0 and cannot be decremented");
    item.renderCounter--;

    // Remove the top item if `renderCounter == 0`
    if (item.renderCounter == 0) {
      restoreFromStack(v, item.state);
      v->_stack.pop();

      // Clean all remaining top elements with `renderCounter == 0` (which have been saved because of the render component).
      while (!v->_stack.empty()) {
        CKComponentContextStackItem &itemFromStack = v->_stack.top();
        if (itemFromStack.renderCounter == 0) {
          restoreFromStack(v, itemFromStack.state);
          v->_stack.pop();
        } else {
          break;
        }
      }
    }
  }

  clearContextValueIfEmpty(v);
}

id CKComponentContextHelper::fetch(id key)
{
  CKComponentContextValue *const v = contextValue(NO);
  return v ? (v->_dictionary[key] ?: [v->_dynamicLookup contextValueForClass:key]) : nil;
}

CKComponentContextContents CKComponentContextHelper::fetchAll()
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v) {
    return {};
  }
  return {
    .objects = [v->_dictionary copy],
    .dynamicLookup = v->_dynamicLookup,
  };
}

CKComponentContextPreviousDynamicLookupState CKComponentContextHelper::setDynamicLookup(id<CKComponentContextDynamicLookup> lookup)
{
  CKComponentContextValue *const v = contextValue(YES);
  const CKComponentContextPreviousDynamicLookupState previousState = {
    .previousContents = [v->_dictionary copy],
    .originalLookup = v->_dynamicLookup,
    .newLookup = lookup,
  };
  v->_dictionary = [NSMutableDictionary dictionary];
  v->_dynamicLookup = lookup;
  return previousState;
}

void CKComponentContextHelper::restoreDynamicLookup(const CKComponentContextPreviousDynamicLookupState &setResult)
{
  CKComponentContextValue *const v = contextValue(YES);
  CKCAssert([v->_dictionary count] == 0, @"Value stored but not yet restored at dynamic lookup restore time");
  CKCAssert(v->_dynamicLookup == setResult.newLookup, @"Lookup unexpectedly mutated");
  v->_dictionary = [NSMutableDictionary dictionaryWithDictionary:setResult.previousContents];
  v->_dynamicLookup = setResult.originalLookup;
  clearContextValueIfEmpty(v);
}
