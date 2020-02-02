// Copyright 2004-present Facebook. All Rights Reserved.

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <vector>

#import <Foundation/NSIndexSet.h>
#import <Foundation/NSRange.h>

namespace CK {
  struct IndexTransform final {
    explicit IndexTransform(NSIndexSet *indexes);

    auto applyOffsetToIndex(NSInteger index) const -> NSInteger;
    auto findRangeAndApplyOffsetToIndex(NSInteger index) const -> NSInteger;

  private:
    struct RangeOffset {
      NSRange range;
      NSInteger offset;
    };

    std::vector<RangeOffset> _rangeOffsets;
  };

  struct RemovalIndexTransform final {
    explicit RemovalIndexTransform(NSIndexSet *indexes) : _t(indexes) {};

    /**
     Given an item index before applying a transform, returns a new index of the same item. For example, given a transform
     created with indexes `{0, 1}` and an input index of 2, this method will return 0 since there were two items removed
     before index 2.

     @param index Item index before applying the trasform.

     @return  Item index after the transform is applied, or `NSNotFound` if the item is no longer present after applying
     the transform.
     */
    auto applyToIndex(NSInteger index) const -> NSInteger { return _t.applyOffsetToIndex(index); }

    /**
     Given an item index after applying the transform, returns an index the same item had before application. For example,
     given a transform created with indexes `{0, 1}` and an input index of 0, this method will return 2 since there were
     two items previously before index 0.

     @param index Item index after applying the transform.

     @return  Item index before the transform was applied. This method never returns `NSNotFound`.
     */
    auto applyInverseToIndex(NSInteger index) const -> NSInteger { return _t.findRangeAndApplyOffsetToIndex(index); }

  private:
    IndexTransform _t;
  };

  struct InsertionIndexTransform final {
    explicit InsertionIndexTransform(NSIndexSet *indexes) : _t(indexes) {};

    auto applyToIndex(NSInteger index) const -> NSInteger { return _t.findRangeAndApplyOffsetToIndex(index); }
    auto applyInverseToIndex(NSInteger index) const -> NSInteger { return _t.applyOffsetToIndex(index); }

  private:
    IndexTransform _t;
  };

  template <typename T1, typename T2>
  struct CompositeIndexTransform final {
    CompositeIndexTransform(T1 &&t1, T2 &&t2)
    : _t1(std::forward<T1>(t1)), _t2(std::forward<T2>(t2)) {}

    auto applyToIndex(NSInteger index) const -> NSInteger
    {
      auto const i = _t1.applyToIndex(index);
      return i != NSNotFound ? _t2.applyToIndex(i) : NSNotFound;
    }

    auto applyInverseToIndex(NSInteger index) const -> NSInteger { return _t2.applyInverseToIndex(_t1.applyInverseToIndex(index)); }

  private:
    T1 _t1;
    T2 _t2;
  };

  template <typename T1, typename T2>
  static auto makeCompositeIndexTransform(T1 &&t1, T2 &&t2) {
    return CompositeIndexTransform<T1, T2>(std::forward<T1>(t1), std::forward<T2>(t2));
  }
}

#endif
