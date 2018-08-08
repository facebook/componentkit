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

#import <ComponentKit/CKStatelessComponent.h>

@interface CKStatelessComponentTests : XCTestCase

@end

@implementation CKStatelessComponentTests

- (void)testStatelessFunctionalComponentIdentifier
{
  const auto identifier = @"MyStatelessComponent";
  const auto sfc = [CKStatelessComponent
                    newWithView:{}
                    component:[CKComponent new]
                    identifier: identifier];
  XCTAssertEqual(sfc.identifier, identifier);
}

@end
