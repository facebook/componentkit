/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentMemoizer.h"

#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKMacros.h"
#import "CKInternalHelpers.h"

#include <map>

static NSString *CKComponentMemoizerThreadKey = @"CKComponentMemoizer";

// Define hash as just pulling out the precomputed hash field
namespace std {
  template <>
  struct hash<CKMemoizationKey> {
    size_t operator ()(CKMemoizationKey a) const {
      return a.hash;
    };
  };
}

@interface _CKComponentMemoizerImpl : NSObject {
  @package

  // Store into the next state, read from the current
  _CKComponentMemoizerImpl *_next;

  // maps CKMemoizationKey -> any number of CKComponent *
  std::unordered_multimap<CKMemoizationKey, CKComponent *> componentCache_;
}

@end


@implementation _CKComponentMemoizerImpl

- (CKComponent *)dequeueComponentForKey:(CKMemoizationKey)key
{
  auto it = componentCache_.find(key);
  if (it != componentCache_.end()) {
    CKComponent *c = it->second;
    // Remove this component from the cache, since you can't mount a component twice
    componentCache_.erase(it);
    return c;
  }
  return nil;
}

- (_CKComponentMemoizerImpl *)next
{
  if (!_next) {
    _next = [[_CKComponentMemoizerImpl alloc] init];
  }
  return _next;
}

- (void)enqueueComponent:(CKComponent *)component forKey:(CKMemoizationKey)key
{
  self.next->componentCache_.insert({key, component});
}

+ (_CKComponentMemoizerImpl *)currentMemoizer
{
  return [[NSThread currentThread] threadDictionary][CKComponentMemoizerThreadKey];
}

+ (void)setCurrentMemoizer:(_CKComponentMemoizerImpl *)memoizer
{
  if (memoizer) {
    [[NSThread currentThread] threadDictionary][CKComponentMemoizerThreadKey] = memoizer;
  } else {
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:CKComponentMemoizerThreadKey];
  }
}

@end

CKComponentMemoizer::CKComponentMemoizer(id previousMemoizerState)
{
  _CKComponentMemoizerImpl *mipl = previousMemoizerState ?: [[_CKComponentMemoizerImpl alloc] init];

  // Push this memoizer onto the current thread
  id current = [_CKComponentMemoizerImpl currentMemoizer];
  previousMemoizer_ = current;
  [_CKComponentMemoizerImpl setCurrentMemoizer:mipl];
};

CKComponentMemoizer::~CKComponentMemoizer()
{
  // Pop memoizer
  [_CKComponentMemoizerImpl setCurrentMemoizer:previousMemoizer_];
}

id CKMemoize(CKMemoizationKey memoizationKey, id (^block)(void))
{
  _CKComponentMemoizerImpl *impl = [_CKComponentMemoizerImpl currentMemoizer];
  CKComponent *component = [impl dequeueComponentForKey:memoizationKey];
  if (!component && block) {
    component = block();
  }
  if (component) {
    [impl enqueueComponent:component forKey:memoizationKey];
  }
  return component;
}

id CKComponentMemoizer::nextMemoizerState()
{
  _CKComponentMemoizerImpl *impl = [_CKComponentMemoizerImpl currentMemoizer];
  return impl ? impl->_next : nil;
}
