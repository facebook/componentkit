// (c) Facebook, Inc. and its affiliates. Confidential and proprietary.

#import "RCComputeRootLayout.h"

#import <unordered_map>

#import <RenderCore/CKInternalHelpers.h>
#import <RenderCore/CKMountable.h>
#import <RenderCore/CKSizeRange.h>
#import <RenderCore/RCLayout.h>

// Considers NaNs equal to each other (unlike CGSizeEqualToSize). This is important for the layout cache
// keys as identical keys that contain NaNs will be otherwise treated as different.
static bool sizesAreEqual(const CGSize &lhs, const CGSize &rhs)
{
  return CKFloatsEqual(lhs.width, rhs.width) && CKFloatsEqual(lhs.height, rhs.height);
}

struct RCLayoutCacheKey {
  CKSizeRange constrainingSize;
  CGSize parentSize;

  bool operator==(const RCLayoutCacheKey &other) const
  {
    return constrainingSize == other.constrainingSize && sizesAreEqual(parentSize, other.parentSize);
  }
};

namespace std {
  template <>
  struct hash<CGSize> {
    size_t operator ()(const CGSize &size) noexcept {
      const auto hashes = {
        std::hash<CGFloat>()(size.width),
        std::hash<CGFloat>()(size.height),
      };
      return RCIntegerArrayHash(hashes.begin(), hashes.size());
    }
  };

  template <>
  struct hash<RCLayoutCacheKey> {
    size_t operator()(const RCLayoutCacheKey &key) const noexcept
    {
      const auto hashes = {
        key.constrainingSize.hash(),
        std::hash<CGSize>()(key.parentSize)
      };
      return RCIntegerArrayHash(hashes.begin(), hashes.size());
    }
  };
}

/** A layout cache is really just an unordered_map, under the covers. */
struct RCLayoutCache {
  std::unordered_map<id<CKMountable>, std::unordered_map<RCLayoutCacheKey, RCLayout>, RC::hash<id>> map;
};

thread_local const RCLayoutCache *currentLayoutReadCache;
thread_local RCLayoutCache *currentLayoutWriteCache;

/**
 Recursively copies layout cache entries for the layout and all of its
 children. This ensures that the layout cache has comprehensive coverage
 of all component layouts, even when we get a cache hit.
 */
static void copyFromReadCacheToWriteCache(const RCLayout &layout,
                                          const RCLayoutCache *readCache,
                                          RCLayoutCache *writeCache)
{
  const auto &matches = readCache->map.find(layout.component);
  if (matches != readCache->map.end()) {
    // Copy all entries in the readCache's map to the writeCache's map,
    // skipping any that are already present.
    writeCache->map[layout.component].insert(
      matches->second.begin(),
      matches->second.end()
    );
  }
  if (layout.children) {
    for (const auto &child : *layout.children) {
      copyFromReadCacheToWriteCache(child.layout, readCache, writeCache);
    }
  }
}

RCLayout RCFetchOrComputeLayout(id<CKMountable> mountable,
                                const CKSizeRange &sizeRange,
                                CGSize parentSize,
                                RCLayout (*layoutFunction)(id<CKMountable> mountable, const CKSizeRange &sizeRange, CGSize parentSize))
{
  const RCLayoutCacheKey key {sizeRange, parentSize};

  if (currentLayoutWriteCache) {
    const auto it = currentLayoutWriteCache->map.find(mountable);
    if (it != currentLayoutWriteCache->map.end()) {
      const auto match = it->second.find(key);
      if (match != it->second.end()) {
        return match->second;
      }
    }
  }

  if (currentLayoutReadCache) {
    const auto it = currentLayoutReadCache->map.find(mountable);
    if (it != currentLayoutReadCache->map.end()) {
      const auto match = it->second.find(key);
      if (match != it->second.end()) {
        // Found a hit! Copy the cached layout for this node *and descendants*
        // from the read cache to the write cache, if there is one.
        if (currentLayoutWriteCache) {
          copyFromReadCacheToWriteCache(
            match->second,
            currentLayoutReadCache,
            currentLayoutWriteCache
          );
        }
        return match->second;
      }
    }
  }
  const RCLayout layout = layoutFunction(mountable, sizeRange, parentSize);
  if (currentLayoutWriteCache) {
    currentLayoutWriteCache->map[mountable].emplace(std::make_pair(key, layout));
  }
  return layout;
}

RCLayoutResult RCComputeRootLayout(id<CKMountable> model,
                                        const CKSizeRange &constrainingSize,
                                        std::shared_ptr<RCLayoutCache> cache)
{

  const auto writeCache = std::make_shared<RCLayoutCache>();
  if (cache) {
    // We expect the writeCache to have about as many elements as the readCache.
    // Reserve the appropriate number of buckets now to avoid rehashing later.
    writeCache->map.reserve(cache->map.size());
  }

  // We don't expect nested root layouts, so the thread-local caches should generally be null.
  // But if a nested root layout *does* happen, we restore the previous caches before returning.
  const RCLayoutCache *const previousReadCache = currentLayoutReadCache;
  RCLayoutCache *const previousWriteCache = currentLayoutWriteCache;
  currentLayoutReadCache = cache.get();
  currentLayoutWriteCache = writeCache.get();
  RCLayout layout = [model layoutThatFits:constrainingSize parentSize:constrainingSize.max];
  currentLayoutReadCache = previousReadCache;
  currentLayoutWriteCache = previousWriteCache;

  return {
    .layout = layout,
    .cache = writeCache,
  };
}

BOOL RCLayoutCacheContainsEntryForMountable(const RCLayoutCache &cache, id<CKMountable> mountable)
{
  return cache.map.find(mountable) != cache.map.end();
}
