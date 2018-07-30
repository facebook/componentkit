// Copyright 2004-present Facebook. All Rights Reserved.

#import <vector>

#import <Foundation/NSIndexSet.h>
#import <Foundation/NSRange.h>

namespace CK {
  struct RangeOffset {
    NSRange range;
    NSInteger offset;
  };

  struct IndexTransformProtocol {
    /**
     Given an item index before applying a transform, returns a new index of the same item. For example, given a transform
     created with indexes `{0, 1}` and an input index of 2, this method will return 0 since there were two items removed
     before index 2.

     @param index Item index before applying the trasform.

     @return  Item index after the transform is applied, or `NSNotFound` if the item is no longer present after applying
     the transform.
     */
    virtual auto applyToIndex(NSInteger index) const -> NSInteger = 0;

    /**
     Given an item index after applying the transform, returns an index the same item had before application. For example,
     given a transform created with indexes `{0, 1}` and an input index of 0, this method will return 2 since there were
     two items previously before index 0.

     @param index Item index after applying the transform.

     @return  Item index before the transform was applied. This method never returns `NSNotFound`.
     */
    virtual auto applyInverseToIndex(NSInteger index) const -> NSInteger = 0;

    virtual ~IndexTransformProtocol() {}
  };

  struct IndexTransform: IndexTransformProtocol {
    explicit IndexTransform(NSIndexSet *indexes);

  protected:
    auto applyOffsetToIndex(NSInteger index) const -> NSInteger;
    auto findRangeAndApplyOffsetToIndex(NSInteger index) const -> NSInteger;

  private:
    std::vector<RangeOffset> _rangeOffsets;
  };

  struct RemovalIndexTransform final: IndexTransform {
    using IndexTransform::IndexTransform;

    auto applyToIndex(NSInteger index) const -> NSInteger { return applyOffsetToIndex(index); }
    auto applyInverseToIndex(NSInteger index) const -> NSInteger { return findRangeAndApplyOffsetToIndex(index); }
  };

  struct InsertionIndexTransform final: IndexTransform {
    using IndexTransform::IndexTransform;

    auto applyToIndex(NSInteger index) const -> NSInteger { return findRangeAndApplyOffsetToIndex(index); }
    auto applyInverseToIndex(NSInteger index) const -> NSInteger { return applyOffsetToIndex(index); }
  };

  struct CompositeIndexTransform final: IndexTransformProtocol {
    CompositeIndexTransform(std::unique_ptr<const IndexTransformProtocol> t1,
                            std::unique_ptr<const IndexTransformProtocol> t2)
    : _t1(std::move(t1)), _t2(std::move(t2)) {}

    auto applyToIndex(NSInteger index) const -> NSInteger { return _t2->applyToIndex(_t1->applyToIndex(index)); }
    auto applyInverseToIndex(NSInteger index) const -> NSInteger { return _t2->applyInverseToIndex(_t1->applyInverseToIndex(index)); }

  private:
    std::unique_ptr<const IndexTransformProtocol> _t1;
    std::unique_ptr<const IndexTransformProtocol> _t2;
  };
}
