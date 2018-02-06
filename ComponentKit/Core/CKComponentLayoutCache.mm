/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentLayoutCache.h"

#import <unordered_map>

#import "CKComponentLayout.h"
#import "CKComponent.h"
#import "CKComponentSubclass.h"

static NSString *const kComponentCacheKey = @"componentCacheKey";

struct CKComponentComparator {
  bool operator() (CKComponent *lhs, CKComponent *rhs) const { return lhs == rhs; }
};

struct CKComponentHasher {
  std::size_t operator() (const CKComponent *c) const { return [c hash]; }
};

@implementation CKComponentLayoutCache
{
  std::unordered_map<CKComponent *, CKComponentLayout, CKComponentHasher, CKComponentComparator> _cache;
}

+ (instancetype)newWithLayout:(const CKComponentLayout &)layout
{
  CKComponentLayoutCache *cache = [CKComponentLayoutCache new];
  if (cache) {
    CKBuildScopedComponentLayoutCache(layout, cache);
  }
  return cache;
}

- (CKComponentLayout)layoutForComponent:(CKComponent *)c
{
  auto const it = _cache.find(c);
  if (it == _cache.end()) {
    return {};
  }
  return it->second;
}

static void CKBuildScopedComponentLayoutCache(const CKComponentLayout &layout, CKComponentLayoutCache *cache)
{
  // We need to cache only components that has a component controller.
  if (layout.component.controller) {
    cache->_cache[layout.component] = layout;
  }

  if (layout.children != nullptr) {
    for (auto const child : *layout.children) {
      CKBuildScopedComponentLayoutCache(child.layout, cache);
    }
  }
}

@end
