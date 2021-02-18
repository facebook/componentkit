// (c) Facebook, Inc. and its affiliates. Confidential and proprietary.

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#import <RenderCore/RCLayout.h>

@protocol CKMountable;
struct RCLayoutCache;

struct RCLayoutResult {
  /** The computed layout */
  RCLayout layout;
  /** Can be passed in on next layout to make things faster */
  std::shared_ptr<RCLayoutCache> cache;
};

/**
 Internal-only helper function that searches for a cached RCLayout
 in the thread-local *read* layout cache.

 If it finds a matching layout in the *read* layout cache, it copies that
 layout (and all cached layouts for its descendants) to the *write*
 layout cache and returns the layout.

 If it does not find a matching layout, it invokes the layoutFunction to
 compute a layout, stores it in the *write* layout cache, and returns it.

 This is intended to be used as a helper when implementing the
 -layoutThatFits:parentSize: method. It should not be used externally.
 */
RCLayout RCFetchOrComputeLayout(
  id<CKMountable> mountable,
  const CKSizeRange &sizeRange,
  CGSize parentSize,
  RCLayout (*layoutFunction)(id<CKMountable> mountable, const CKSizeRange &sizeRange, CGSize parentSize)
);

/** Intended for use in tests only. */
BOOL RCLayoutCacheContainsEntryForMountable(
  const RCLayoutCache &cache,
  id<CKMountable> mountable
);


RCLayoutResult RCComputeRootLayout(id<CKMountable> model,
                                        const CKSizeRange &constrainingSize,
                                        std::shared_ptr<RCLayoutCache> cache);

#endif
