/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentDataSourceTestDelegate.h"

#import <ComponentKit/CKComponentDataSource.h>
#import <ComponentKit/CKComponentDataSourceOutputItem.h>
#import <ComponentKit/ComponentUtilities.h>

using namespace CK::ArrayController;

@implementation CKComponentDataSourceTestDelegateChange

- (BOOL)isEqual:(id)object
{
  return CKCompareObjectEquality(self, object, ^BOOL (CKComponentDataSourceTestDelegateChange *change, CKComponentDataSourceTestDelegateChange *changeToCompare) {
    return (
            CKObjectIsEqual(change.dataSourcePair, changeToCompare.dataSourcePair) &&
            CKObjectIsEqual(change.oldDataSourcePair, changeToCompare.oldDataSourcePair) &&
            change.changeType == changeToCompare.changeType &&
            CKObjectIsEqual(change.beforeIndexPath, changeToCompare.beforeIndexPath) &&
            CKObjectIsEqual(change.afterIndexPath, changeToCompare.afterIndexPath)
    );
  });
}

@end

@implementation CKComponentDataSourceTestDelegate {
  NSMutableArray *_changes;
}

- (id)init
{
  if (self = [super init]) {
    _changes = [[NSMutableArray alloc] init];
    _changeCount = 0;
  }
  return self;
}

- (void)reset
{
  [_changes removeAllObjects];
  _changeCount = 0;
}

- (NSArray *)changes
{
  return _changes;
}

- (void)componentDataSource:(CKComponentDataSource *)componentDataSource
          hasChangesOfTypes:(CKComponentDataSourceChangeType)changeTypes
        changesetApplicator:(ck_changeset_applicator_t)changesetApplicator
{
  const auto &changeset = changesetApplicator();

  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *indexes, CKArrayControllerChangeType type, BOOL *stop) {};

  Output::Items::Enumerator itemsEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {

    CKComponentDataSourceTestDelegateChange *delegateChange = [[CKComponentDataSourceTestDelegateChange alloc] init];
    delegateChange.dataSourcePair = change.after;
    delegateChange.oldDataSourcePair = change.before;
    delegateChange.beforeIndexPath = (type == CKArrayControllerChangeTypeInsert) ? nil : change.indexPath.toNSIndexPath();
    delegateChange.afterIndexPath = (type == CKArrayControllerChangeTypeDelete) ? nil : change.indexPath.toNSIndexPath();
    delegateChange.changeType = type;
    [_changes addObject:delegateChange];

  };

  changeset.enumerate(sectionsEnumerator, itemsEnumerator);

  _changeCount++;
  if (_onChange) {
    _onChange(_changeCount);
  }

}

- (void)componentDataSource:(CKComponentDataSource *)componentDataSource
     didChangeSizeForObject:(CKComponentDataSourceOutputItem *)object
                atIndexPath:(NSIndexPath *)indexPath
                  animation:(const CKComponentBoundsAnimation &)animation
{
}

@end
