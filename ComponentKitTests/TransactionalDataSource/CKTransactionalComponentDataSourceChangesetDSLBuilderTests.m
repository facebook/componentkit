/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "CKTransactionalComponentDataSourceChangeset.h"
#import "CKTransactionalComponentDataSourceChangesetInternal.h"

static NSIndexPath *indexPath(NSInteger item, NSInteger section) {
  return [NSIndexPath indexPathForItem:item inSection:section];
}

@interface CKTransactionalComponentDataSourceChangesetDSLBuilderTests : XCTestCase
@property (strong) CKTransactionalComponentDataSourceChangeset *changeset;
@end

@implementation CKTransactionalComponentDataSourceChangesetDSLBuilderTests

- (void)testInsertions
{
  self.changeset =
  [CKTransactionalComponentDataSourceChangesetDSLBuilder build:^(CKTransactionalComponentDataSourceChangesetDSLBuilder *builder)
   {
     builder.insert.section.at.index(0);
     builder.insert.item(@"Foo").at.ck_indexPath(0, 0);
     builder.insert.item(@"Bar").at.ck_indexPath(1, 0);
   }];

  XCTAssertEqualObjects(self.changeset.insertedSections, [NSIndexSet indexSetWithIndex:0]);
  XCTAssertEqualObjects(self.changeset.insertedItems, (@{ indexPath(0, 0) : @"Foo", indexPath(1, 0) : @"Bar" }));
}

- (void)testRemovals
{
  self.changeset =
  [CKTransactionalComponentDataSourceChangesetDSLBuilder build:^(CKTransactionalComponentDataSourceChangesetDSLBuilder *builder)
   {
     builder.ck_removeItem.at.ck_indexPath(10, 5);
     builder.remove.item(nil).at.ck_indexPath(1, 1);
     builder.remove.section.at.index(1);
     builder.remove.section.at.index(2);
   }];

  XCTAssertEqualObjects(self.changeset.removedSections, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]);
  XCTAssertEqualObjects(self.changeset.removedItems, ([NSSet setWithObjects:indexPath(10, 5), indexPath(1, 1), nil]));
}

- (void)testUpdates
{
  self.changeset =
  [CKTransactionalComponentDataSourceChangesetDSLBuilder build:^(CKTransactionalComponentDataSourceChangesetDSLBuilder *builder) {
    builder.update.item(@"Foo").at.ck_indexPath(5, 6);
    builder.update.at.ck_indexPath(1, 1).with.item(@"Bar");
  }];

  XCTAssertEqualObjects(self.changeset.updatedItems, (@{ indexPath(5, 6) : @"Foo", indexPath(1, 1) : @"Bar" }));
}

- (void)testMoves
{
  self.changeset =
  [CKTransactionalComponentDataSourceChangesetDSLBuilder build:^(CKTransactionalComponentDataSourceChangesetDSLBuilder *builder) {
    builder.ck_moveItem.at.ck_indexPath(0, 0).to.ck_indexPath(4, 4);
    builder.move.item(nil).at.ck_indexPath(3, 3).to.ck_indexPath(1, 0);
    builder.move.section.at.index(0).to.index(4);
  }];

  XCTAssertEqualObjects(self.changeset.movedItems, (@{ indexPath(0, 0) : indexPath(4, 4), indexPath(3, 3) : indexPath(1, 0) }));
  XCTAssertEqualObjects(self.changeset.movedSections, (@{ @0 : @4 }));
}

@end
