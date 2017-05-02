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

#import <ComponentKit/CKComponentKey.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

@interface CKComponentKeyTests : XCTestCase
@end

@implementation CKComponentKeyTests

- (void)testComponentScopeStateIsDistinguishedByKey
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentScopeRoot *root2;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentKey key(@"foo");
      CKComponentScope scope([CKCompositeComponent class], nil, ^{ return @42; });
    }
    root2 = CKThreadLocalComponentScope::currentScope()->newScopeRoot;
  }
  {
    CKThreadLocalComponentScope threadScope(root2, {});
    {
      CKComponentKey key(@"bar");
      CKComponentScope scope([CKCompositeComponent class], nil, ^{ return @365; });
      XCTAssertEqualObjects(scope.state(), @365, @"Key changing from foo to bar should cause separate state");
    }
  }
}

@end
