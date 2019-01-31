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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKDataSourceConfiguration.h>

@interface CKDataSourceConfigurationTests : XCTestCase
@end

@implementation CKDataSourceConfigurationTests

- (void)testConfigurationEquality
{
  CKDataSourceConfiguration *firstConfiguration =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[CKDataSourceConfigurationTests class]
                                                       context:@"context"
                                                     sizeRange:CKSizeRange()];
  CKDataSourceConfiguration *secondConfiguration =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[CKDataSourceConfigurationTests class]
                                                       context:@"context"
                                                     sizeRange:CKSizeRange()];
  XCTAssertEqualObjects(firstConfiguration, secondConfiguration);
}

- (void)test_WhenComponentProvidersAreDifferent_NotEqual
{
  auto const c1 =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[CKDataSourceConfigurationTests class]
                                                       context:@"context"
                                                     sizeRange:CKSizeRange()];
  auto const c2 =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[UIView class]
                                                       context:@"context"
                                                     sizeRange:CKSizeRange()];
  XCTAssertNotEqualObjects(c1, c2);
}

- (void)test_WhenContextsAreDifferent_NotEqual
{
  CKDataSourceConfiguration *firstConfiguration =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[CKDataSourceConfigurationTests class]
                                                       context:@"context"
                                                     sizeRange:CKSizeRange()];
  CKDataSourceConfiguration *secondConfiguration =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[CKDataSourceConfigurationTests class]
                                                       context:@"context2"
                                                     sizeRange:CKSizeRange()];
  XCTAssertNotEqualObjects(firstConfiguration, secondConfiguration);
}

- (void)test_WhenSizeRangesAreDifferent_NotEqual
{
  auto const c1 =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[CKDataSourceConfigurationTests class]
                                                       context:@"context"
                                                     sizeRange:CKSizeRange()];
  auto const c2 =
  [[CKDataSourceConfiguration alloc] initWithComponentProvider:[CKDataSourceConfigurationTests class]
                                                       context:@"context"
                                                     sizeRange:{CGSizeZero, {100, 100}}];
  XCTAssertNotEqualObjects(c1, c2);
}

@end
