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

/**
 * Subclass this instead of `XCTestCase` if you would like to create component without going through
 * `CKBuildComponent` in your tests.
 */
@interface CKComponentTestCase : XCTestCase

@end
