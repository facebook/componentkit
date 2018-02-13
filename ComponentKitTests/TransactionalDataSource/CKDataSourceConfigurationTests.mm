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
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKDataSourceConfiguration.h>

@interface CKDataSourceConfigurationTests : XCTestCase <CKComponentProvider>
@end

@implementation CKDataSourceConfigurationTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKComponent newWithView:{} size:{}];
}

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

- (void)testNonEqualConfigurations
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

@end
