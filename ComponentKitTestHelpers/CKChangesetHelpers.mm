// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKChangesetHelpers.h"

#import <UIKit/UIKit.h>

#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKitTestHelpers/NSIndexSetExtensions.h>

auto CK::IndexPath::toCocoa() const -> NSIndexPath *
{
  return [NSIndexPath indexPathForItem:item inSection:section];
}

static auto makeIndexPathSet(const std::vector<CK::IndexPath> ips) -> NSSet<NSIndexPath *> *
{
  auto r = static_cast<NSMutableSet<NSIndexPath *> *>([NSMutableSet new]);
  for (const auto &ip : ips) {
    [r addObject:ip.toCocoa()];
  }
  return r;
}

static auto makeItemsByIndexPathDictionary(const CK::ChangesetParams::ItemsByIndexPath& itemsByIndexPath) -> NSDictionary <NSIndexPath *, NSObject *> *
{
  auto r = static_cast<NSMutableDictionary<NSIndexPath *, NSObject *> *>([NSMutableDictionary new]);
  for (const auto &kv : itemsByIndexPath) {
    r[kv.first.toCocoa()] = kv.second;
  }
  return r;
}

static auto makeIndexPathsByIndexPathDictionary(const CK::ChangesetParams::IndexPathsByIndexPath& indexPaths) -> NSDictionary <NSIndexPath *, NSIndexPath *> *
{
  auto r = static_cast<NSMutableDictionary<NSIndexPath *, NSIndexPath *> *>([NSMutableDictionary new]);
  for (const auto &kv : indexPaths) {
    r[kv.first.toCocoa()] = kv.second.toCocoa();
  }
  return r;
}

auto CK::makeChangeset(const CK::ChangesetParams &params) -> CKDataSourceChangeset *
{
  return [[[[[[[[CKDataSourceChangesetBuilder dataSourceChangeset]
                withUpdatedItems:makeItemsByIndexPathDictionary(params.updatedItems)]
               withRemovedItems:makeIndexPathSet(params.removedItems)]
              withRemovedSections:CK::makeIndexSet(params.removedSections)]
             withMovedItems:makeIndexPathsByIndexPathDictionary(params.movedItems)]
            withInsertedItems:makeItemsByIndexPathDictionary(params.insertedItems)]
           withInsertedSections:CK::makeIndexSet(params.insertedSections)] build];
}
