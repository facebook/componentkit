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
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKit/CKRootTreeNode.h>

#import <stack>

static NSString *const kThreadDictionaryKey = @"CKComponentContext";

struct CKComponentContextStackItem {
  NSMutableDictionary *dictionary;
  BOOL itemWasAdded;
};

@interface CKComponentContextValue : NSObject
{
@public
  // The main store.
  NSMutableDictionary *_dictionary;
  // A map between render component to its dictionary.
  NSMapTable<id, NSMutableDictionary *> *_renderToDictionaryCache;
  // Stack of previous store dictionaries.
  std::stack<CKComponentContextStackItem> _stack;
  // Dirty flag for the current store in use.
  BOOL _itemWasAdded;
  // A pointer to the existing scope root, which we set only if `enableFasterPropsUpdates` is enabled.
  __weak CKComponentScopeRoot *_scopeRoot;
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
    threadDictionary[kThreadDictionaryKey] = contextValue;
    // Props updates support.
    CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
    // Save the existing scope root.
    if (currentScope != nullptr && currentScope->newScopeRoot) {
      contextValue->_scopeRoot = currentScope->newScopeRoot;
    } else {
      contextValue->_scopeRoot = nil;
    }
  }
  return contextValue;
}

bool CKComponentContextContents::operator==(const CKComponentContextContents &other) const
{
  return ((other.objects == nil && objects == nil) || [other.objects isEqualToDictionary:objects]);
}

bool CKComponentContextContents::operator!=(const CKComponentContextContents &other) const
{
  return !(*this == other);
}

static void clearContextValueIfEmpty(CKComponentContextValue *const currentValue)
{
  if ([currentValue->_dictionary count] == 0 && currentValue->_renderToDictionaryCache.count == 0) {
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

void CKComponentContextHelper::didCreateRenderComponent(id component)
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v) {
    return;
  }

  // Make a backup dictionary if needed and store it in the _renderToDictionaryCache map.
  if (v->_itemWasAdded) {
    NSMutableDictionary *renderDictionary = [v->_dictionary mutableCopy];
    [v->_renderToDictionaryCache setObject:renderDictionary forKey:component];
  }
}

void CKComponentContextHelper::willBuildComponentTree(id component)
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v) {
    return;
  }

  NSMutableDictionary *renderDictionary = [v->_renderToDictionaryCache objectForKey:component];
  if (renderDictionary) {
    // Push the current store into the stack.
    v->_stack.push({
      .dictionary = v->_dictionary,
      .itemWasAdded = v->_itemWasAdded,
    });
    // Update the pointer to the latest render dictionary
    v->_dictionary = renderDictionary;
    v->_itemWasAdded = NO;
  }
}

void CKComponentContextHelper::didBuildComponentTree(id component)
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v) {
    return;
  }

  NSMutableDictionary *renderDictionary = [v->_renderToDictionaryCache objectForKey:component];
  if (renderDictionary) {
    CKCAssert(!v->_stack.empty(), @"The stack cannot be empty if there is a render dictionary in the cache");
    CKCAssert(v->_dictionary == renderDictionary, @"The current store is different than the renderDictionary");

    // Update the pointer to the latest render dictionary
    if (!v->_stack.empty()) {
      // Retrieve the previous value from the stack.
      auto const &topItem = v->_stack.top();
      v->_dictionary = topItem.dictionary;
      v->_itemWasAdded = topItem.itemWasAdded;
      // Pop the top backup from the stack
      v->_stack.pop();
      // Remove the dictionary from the map
      [v->_renderToDictionaryCache removeObjectForKey:component];
    }
    clearContextValueIfEmpty(v);
  }
}

id CKComponentContextHelper::fetchMutable(id key)
{
  CKComponentContextValue *const v = contextValue(NO);
  if (v) {
    auto const scopeRoot = v->_scopeRoot;
    if (scopeRoot) {
      scopeRoot.rootNode.markTopRenderComponentAsDirtyForPropsUpdates();
    }
    return v->_dictionary[key];
  }
  return nil;
}

id CKComponentContextHelper::fetch(id key)
{
  CKComponentContextValue *const v = contextValue(NO);
  if (v) {
    return v->_dictionary[key];
  }
  return nil;
}

CKComponentContextContents CKComponentContextHelper::fetchAll()
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v) {
    return {};
  }

  return {
    .objects = [v->_dictionary copy],
  };
}

NSMutableDictionary<Class, id>* CKComponentInitialValuesContext::setInitialValues(NSDictionary<Class, id> *objects)
{
  CKComponentContextValue *const v = contextValue(YES);
  // Save the old values.
  auto const oldObjects = v->_dictionary;
  // Copy the new values.
  v->_dictionary = [objects mutableCopy];
  // Move the old values back to the main storage.
  for (id key in oldObjects) {
    v->_dictionary[key] = oldObjects[key];
  }
  return oldObjects;
}

void CKComponentInitialValuesContext::cleanInitialValues(NSMutableDictionary<Class, id> *oldObjects)
{
  CKComponentContextValue *const v = contextValue(NO);
  if (!v) {
    return;
  }
  v->_dictionary = oldObjects;
  clearContextValueIfEmpty(v);
}
