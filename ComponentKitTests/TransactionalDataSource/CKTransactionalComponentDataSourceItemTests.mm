/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <XCTest/XCTest.h>

#import "CKComponentLayout.h"
#import "CKComponentScopeRoot.h"
#import "CKTransactionalComponentDataSourceItemInternal.h"

@interface CKTransactionalComponentDataSourceItemTests : XCTestCase
@end

@implementation CKTransactionalComponentDataSourceItemTests

- (void)testEqualItems
{
  CKTransactionalComponentDataSourceItem *item1 = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:CKComponentLayout() model:@"Hello" scopeRoot:nil];
  CKTransactionalComponentDataSourceItem *item2 = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:CKComponentLayout() model:@"Hello" scopeRoot:nil];
  XCTAssertEqualObjects(item1, item2);
}

- (void)testNonEqualItems
{
  CKTransactionalComponentDataSourceItem *item1 = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:CKComponentLayout() model:@"Hello" scopeRoot:nil];
  CKTransactionalComponentDataSourceItem *item2 = [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:CKComponentLayout() model:@"Hello2" scopeRoot:nil];
  XCTAssertNotEqualObjects(item1, item2);
}

@end
