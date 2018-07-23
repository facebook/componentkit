// Copyright 2004-present Facebook. All Rights Reserved.

#import <unordered_map>
#import <vector>

#import <Foundation/NSObject.h>

@class NSIndexPath;
@class CKDataSourceChangeset;

namespace CK {
  struct IndexPath {
    struct EqualTo {
      auto operator()(const IndexPath& lhs, const IndexPath& rhs) const noexcept
      {
        return lhs.section == rhs.section && lhs.item == rhs.item;
      }
    };
    struct Hash {
      auto operator()(const IndexPath& ip) const noexcept { return ip.item ^ ip.section; }
    };

    const int section;
    const int item;

    auto toCocoa() const -> NSIndexPath *;
  };

  struct ChangesetParams {
    using ItemsByIndexPath = std::unordered_map<IndexPath, NSObject *, CK::IndexPath::Hash, CK::IndexPath::EqualTo>;
    using IndexPathsByIndexPath = std::unordered_map<IndexPath, IndexPath, CK::IndexPath::Hash, CK::IndexPath::EqualTo>;

    const ItemsByIndexPath updatedItems = {};
    const std::vector<IndexPath> removedItems = {};
    const std::vector<NSUInteger> removedSections = {};
    const IndexPathsByIndexPath movedItems = {};
    const std::vector<NSUInteger> insertedSections = {};
    const ItemsByIndexPath insertedItems = {};
  };

  auto makeChangeset(const CK::ChangesetParams &params) -> CKDataSourceChangeset *;
}

