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

static NSString *const kThreadDictionaryKey = @"CKComponentContext";

static NSMutableDictionary *contextDictionary(BOOL create)
{
  NSMutableDictionary *const threadDictionary = [[NSThread currentThread] threadDictionary];
  NSMutableDictionary *contextDictionary = [threadDictionary objectForKey:kThreadDictionaryKey];
  if (contextDictionary == nil && create) {
    contextDictionary = [NSMutableDictionary dictionary];
    [threadDictionary setObject:contextDictionary forKey:kThreadDictionaryKey];
  }
  return contextDictionary;
}

CKComponentContextPreviousState CKComponentContextHelper::store(id key, id object)
{
  NSMutableDictionary *const c = contextDictionary(YES);
  id originalValue = c[key];
  c[key] = object;
  return {.key = key, .originalValue = originalValue, .newValue = object};
}

void CKComponentContextHelper::restore(const CKComponentContextPreviousState &storeResult)
{
  // We want to create the context dictionary if it doesn't exist already, because we need to restore the original
  // value. In practice it should always exist already except for an obscure edge case; see the unit test
  // testTriplyNestedComponentContextWithNilMiddleValueCorrectlyRestoresOuterValue for an example.
  NSMutableDictionary *const c = contextDictionary(YES);
  CKCAssert(c[storeResult.key] == storeResult.newValue, @"Context value for %@ unexpectedly mutated", storeResult.key);
  c[storeResult.key] = storeResult.originalValue;
  if ([c count] == 0) {
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:kThreadDictionaryKey];
  }
}

id CKComponentContextHelper::fetch(id key)
{
  return contextDictionary(NO)[key];
}
