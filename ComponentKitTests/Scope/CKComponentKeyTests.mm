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
#import <ComponentKit/ComponentUtilities.h>

@interface CKComponentKeyTests : XCTestCase
@end

/** Implements isEqual and hash in terms of the underlying key string. */
@interface CKKeyWrapper : NSObject
- (instancetype)initWithKey:(NSString *)key;
@end

@implementation CKComponentKeyTests

- (void)testComponentScopeStateIsDistinguishedByKey
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil, nil);
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

- (void)testComponentScopeStateIsRecoveredWithKeysThatAreEqualButNotPointerIdentical
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  CKComponentScopeRoot *root2;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentKey key([[CKKeyWrapper alloc] initWithKey:@"foo"]);
      CKComponentScope scope([CKCompositeComponent class], nil, ^{ return @42; });
    }
    root2 = CKThreadLocalComponentScope::currentScope()->newScopeRoot;
  }
  {
    CKThreadLocalComponentScope threadScope(root2, {});
    {
      CKComponentKey key([[CKKeyWrapper alloc] initWithKey:@"foo"]);
      CKComponentScope scope([CKCompositeComponent class], nil, ^{ return @365; });
      XCTAssertEqualObjects(scope.state(), @42, @"Even though key is not pointer equal, it is isEqual equal");
    }
  }
}

@end

@implementation CKKeyWrapper
{
  NSString *_key;
}

- (instancetype)initWithKey:(NSString *)key
{
  if (self = [super init]) {
    _key = [key copy];
  }
  return self;
}

- (BOOL)isEqual:(id)object
{
  return CKCompareObjectEquality(self, object, ^(CKKeyWrapper *a, CKKeyWrapper *b){
    return [a->_key isEqual:b->_key];
  });
}

- (NSUInteger)hash
{
  return [_key hash];
}

@end
