// Copyright 2004-present Facebook. All Rights Reserved.

#import <vector>

#import <Foundation/NSIndexSet.h>
#import <Foundation/NSRange.h>

namespace CK {
  struct RangeOffset {
    NSRange range;
    NSInteger offset;
  };

  struct IndexTransform {
    /**
     @param removedIndexes  Indexes of removed items. Nil or empty collection will create an identity transform.
     */
    explicit IndexTransform(NSIndexSet *removedIndexes);

    /**
     Given an item index before applying a transform, returns a new index of the same item. For example, given a transform
     created with indexes `{0, 1}` and an input index of 2, this method will return 0 since there were two items removed
     before index 2.

     @param index Item index before applying the trasform.

     @return  Item index after the transform is applied, or `NSNotFound` if the item is no longer present after applying
     the transform.
     */
    auto applyToIndex(NSInteger index) const -> NSInteger;

    /**
     Given an item index after applying the transform, returns an index the same item had before application. For example,
     given a transform created with indexes `{0, 1}` and an input index of 0, this method will return 2 since there were
     two items previously before index 0.

     @param index Item index after applying the transform.

     @return  Item index before the transform was applied. This method never returns `NSNotFound`.
     */
    auto applyInverseToIndex(NSInteger index) const -> NSInteger;

  private:
    std::vector<RangeOffset> _rangeOffsets;
  };
}
