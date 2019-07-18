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

#import <ComponentKit/CKInternalHelpers.h>

@interface Subclass: NSObject
- (void)method;
+ (void)classMethod;
@end

@interface CKSubclassOverridesSelectorMethodTests : XCTestCase
@end

@implementation CKSubclassOverridesSelectorMethodTests

- (void)test_InstanceMethod_WhenSuperclassIsNil_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesInstanceMethod(Nil, [NSObject class], @selector(description)));
}

- (void)test_InstanceMethod_WhenSubclassIsNil_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesInstanceMethod([NSObject class], Nil, @selector(description)));
}

- (void)test_InstanceMethod_IfSuperclassDoesNotImplementSelector_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesInstanceMethod([NSObject class], [Subclass class], @selector(method)));
}

- (void)test_InstanceMethod_IfClassesAreNotRelated_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesInstanceMethod([NSObject class], [NSProxy class], @selector(description)));
}

- (void)test_InstanceMethod_IfSubclassDoesNotOverrideMethod_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesInstanceMethod([NSObject class], [Subclass class], @selector(isEqual:)));
}

- (void)test_InstanceMethod_IfSubclassOverridesMethod_DoesConsiderAsOverride
{
  XCTAssertTrue(CKSubclassOverridesInstanceMethod([NSObject class], [Subclass class], @selector(description)));
}

- (void)test_ClassMethod_WhenSuperclassIsNil_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesClassMethod(Nil, [NSObject class], @selector(description)));
}

- (void)test_ClassMethod_WhenSubclassIsNil_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesClassMethod([NSObject class], Nil, @selector(description)));
}

- (void)test_ClassMethod_IfSuperclassDoesNotImplementSelector_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesClassMethod([NSObject class], [Subclass class], @selector(classMethod)));
}

- (void)test_ClassMethod_IfClassesAreNotRelated_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesClassMethod([NSObject class], [NSProxy class], @selector(description)));
}

- (void)test_ClassMethod_IfSubclassDoesNotOverrideMethod_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesClassMethod([NSObject class], [Subclass class], @selector(load)));
}

- (void)test_ClassMethod_IfSubclassOverridesMethod_DoesConsiderAsOverride
{
  XCTAssertTrue(CKSubclassOverridesClassMethod([NSObject class], [Subclass class], @selector(debugDescription)));
}

@end

@implementation Subclass

- (void)method {}
+ (void)classMethod {}

- (NSString *)description
{
  return @"";
}

+ (NSString *)debugDescription
{
  return @"";
}

@end
