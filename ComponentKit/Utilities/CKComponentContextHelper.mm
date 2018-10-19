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

@interface CKComponentContextValue : NSObject
{
@public
  // The main store.
  NSMutableDictionary *_dictionary;
  // A map between render component to its dictionary.
  NSMapTable<id, NSMutableDictionary *> *_renderToDictionaryCache;
  // Stack of previous store dictionaries.
  std::stack<NSMutableDictionary *> _stack;
  // Dirty flag for the current store in use.
  BOOL _itemWasAdded;
  // Enable the render support.
  BOOL _enableRenderSupport;

  id<CKComponentContextDynamicLookup> _dynamicLookup;
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
    contextValue->_renderToDictionaryCache = [NSMapTable weakToStrongObjectsMapTable];
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
  if ([currentValue->_dictionary count] == 0 && currentValue->_renderToDictionaryCache.count == 0 && currentValue->_dynamicLookup == nil) {
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:kThreadDictionaryKey];
  }
}

CKComponentContextPreviousState CKComponentContextHelper::store(id key, id object)
{
  CKComponentContextValue *v = contextValue(YES);
  NSMutableDictionary *const c = v->_dictionary;
  id originalValue = c[key];
  c[key] = object;
  v->_itemWasAdded = YES;
  CKComponentContextPreviousState state = {.key = key, .originalValue = originalValue, .newValue = object};
  return state;
}

void CKComponentContextHelper::restore(const CKComponentContextPreviousState &storeResult)
{
  // We want to create the context dictionary if it doesn't exist already, because we need to restore the original
  // value. In practice it should always exist already except for an obscure edge case; see the unit test
  // testTriplyNestedComponentContextWithNilMiddleValueCorrectlyRestoresOuterValue for an example.
  CKComponentContextValue *const v = contextValue(YES);
  NSMutableDictionary *const c = v->_dictionary;
  CKCAssert(c[storeResult.key] == storeResult.newValue, @"Context value for %@ unexpectedly mutated", storeResult.key);
  c[storeResult.key] = storeResult.originalValue;
  clearContextValueIfEmpty(v);
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

void CKComponentContextHelper::didCreateRenderComponent(id component)
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v || !v->_enableRenderSupport) {
    return;
  }

  // Make a backup dictionary if needed and store it in the _renderToDictionaryCache map.
  if (v->_itemWasAdded) {
    NSMutableDictionary *renderDictionary = [v->_dictionary mutableCopy];
    [v->_renderToDictionaryCache setObject:renderDictionary forKey:component];
    v->_itemWasAdded = NO;
  }
}

void CKComponentContextHelper::willBuildComponentTree(id component)
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v || !v->_enableRenderSupport) {
    return;
  }

  NSMutableDictionary *renderDictionary = [v->_renderToDictionaryCache objectForKey:component];
  if (renderDictionary) {
    // Push the current store into the stack.
    v->_stack.push(v->_dictionary);
    // Update the pointer to the latest render dictionary
    v->_dictionary = renderDictionary;
  }
}

void CKComponentContextHelper::didBuildComponentTree(id component)
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v || !v->_enableRenderSupport) {
    return;
  }

  NSMutableDictionary *renderDictionary = [v->_renderToDictionaryCache objectForKey:component];
  if (renderDictionary) {
    CKCAssert(!v->_stack.empty(), @"The stack cannot be empty if there is a render dictionary in the cache");
    CKCAssert(v->_dictionary == renderDictionary, @"The current store is different than the renderDictionary");
    
    // Update the pointer to the latest render dictionary
    if (!v->_stack.empty()) {
      v->_dictionary = v->_stack.top();
      // Pop the top backup from the stack
      v->_stack.pop();
      // Remove the dictionary from the map
      [v->_renderToDictionaryCache removeObjectForKey:component];
    }
    clearContextValueIfEmpty(v);
  }
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
