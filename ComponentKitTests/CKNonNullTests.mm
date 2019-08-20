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

#import <ComponentKit/CKNonNull.h>

using namespace CK;

@interface CKRelaxedNonNullPtrTests : XCTestCase
@end

@implementation CKRelaxedNonNullPtrTests

- (void)test_ImplicitConversionFromNullable
{
  auto const nullableSet = [NSSet set];
  RelaxedNonNull<NSSet *> nonNullSet = nullableSet;

  XCTAssertEqual(nonNullSet, nullableSet);
}

- (void)compileTimeChecks
{
  auto nn = RelaxedNonNull<NSObject *>([NSObject new]);

//  if (nn) {}
//  auto nn1 = RelaxedNonNull<NSObject *>{nil};
//  nn = nil;
//  if (nn == nil) {}
//  if (nn != nil) {}
//  auto nn2 = RelaxedNonNull<RelaxedNonNull<NSObject *>>{nn};
}

@end

@interface CKNonNullPtrTests : XCTestCase
@end

@implementation CKNonNullPtrTests

- (void)test_ImplicitConversionToNullable
{
  auto const o = [NSObject new];
  auto const nn = makeNonNull(o);

  XCTAssertEqual([nn isProxy], [o isProxy]);
}

- (void)test_ConversionConstructorFromDerivedPtrType
{
  auto const ms = makeNonNull([NSMutableSet new]);
  NonNull<NSSet *> s = ms;

  XCTAssertEqualObjects(ms, s);
}

- (void)test_ImplicitConversionToNullablePtrToBase
{
  auto const nnms = makeNonNull([NSMutableSet new]);
  NSSet *set = nnms;

  XCTAssertEqualObjects(set, nnms);
}

struct ConstructibleFromNullablePtrToBase {
  ConstructibleFromNullablePtrToBase(NSObject *o) : obj(o) {}

  NSObject *obj;
};

- (void)test_ImplicitConversionToConstructibleFromNullable
{
  auto s = makeNonNull([NSSet set]);

  ConstructibleFromNullablePtrToBase c = s;

  XCTAssertEqual(c.obj, s);
}

- (void)compileTimeChecks
{
  auto nn = makeNonNull([NSObject new]);

//  if (nn) {}
//  auto nn1 = NonNull<NSObject *>{nil};
//  nn = nil;
//  if (nn == nil) {}
//  if (nn != nil) {}
//  auto nn2 = makeNonNull(nn);
}

@end
