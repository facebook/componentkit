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
@end

@interface CKSubclassOverridesSelectorTests : XCTestCase
@end

@implementation CKSubclassOverridesSelectorTests

- (void)test_WhenSuperclassIsNil_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesSelector(Nil, [NSObject class], @selector(description)));
}

- (void)test_WhenSubclassIsNil_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesSelector([NSObject class], Nil, @selector(description)));
}

- (void)test_IfSuperclassDoesNotImplementSelector_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesSelector([NSObject class], [Subclass class], @selector(method)));
}

- (void)test_IfClassesAreNotRelated_DoesNotConsiderAsOverride
{
  XCTAssertFalse(CKSubclassOverridesSelector([NSObject class], [NSProxy class], @selector(description)));
}

@end

@implementation Subclass
- (void)method {}
@end
