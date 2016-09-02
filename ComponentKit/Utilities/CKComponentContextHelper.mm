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
  NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
  NSMutableDictionary *contextDictionary = [threadDictionary objectForKey:kThreadDictionaryKey];
  if (contextDictionary == nil && create) {
    contextDictionary = [NSMutableDictionary dictionary];
    [threadDictionary setObject:contextDictionary forKey:kThreadDictionaryKey];
  }
  return contextDictionary;
}

void CKComponentContextHelper::store(id key, id object)
{
  CKCAssertNotNil(object, @"Cannot store nil objects");
  NSMutableDictionary *c = contextDictionary(YES);
  CKCAssertNil(c[key], @"Cannot store %@ = %@ as %@ already exists", key, object, c[key]);
  c[key] = object;
}

void CKComponentContextHelper::clear(id key)
{
  NSMutableDictionary *c = contextDictionary(NO);
  CKCAssertNotNil(c[key], @"Who removed %@ behind our back?", key);
  [c removeObjectForKey:key];
  if ([c count] == 0) {
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:kThreadDictionaryKey];
  }
}

id CKComponentContextHelper::fetch(id key)
{
  return contextDictionary(NO)[key];
}
