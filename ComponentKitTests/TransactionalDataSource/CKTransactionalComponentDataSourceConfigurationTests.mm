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
#import <ComponentKit/CKTransactionalComponentDataSourceConfiguration.h>

@interface CKTransactionalComponentDataSourceConfigurationTests : XCTestCase <CKComponentProvider>
@end

@implementation CKTransactionalComponentDataSourceConfigurationTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKComponent newWithView:{} size:{}];
}

- (void)testConfigurationEquality
{
  CKTransactionalComponentDataSourceConfiguration *firstConfiguration = [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[CKTransactionalComponentDataSourceConfigurationTests class] context:@"context" sizeRange:CKSizeRange()];
  CKTransactionalComponentDataSourceConfiguration *secondConfiguration = [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[CKTransactionalComponentDataSourceConfigurationTests class] context:@"context" sizeRange:CKSizeRange()];
  XCTAssertEqualObjects(firstConfiguration, secondConfiguration);
}

- (void)testNonEqualConfigurations
{
  CKTransactionalComponentDataSourceConfiguration *firstConfiguration = [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[CKTransactionalComponentDataSourceConfigurationTests class] context:@"context" sizeRange:CKSizeRange()];
  CKTransactionalComponentDataSourceConfiguration *secondConfiguration = [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:[CKTransactionalComponentDataSourceConfigurationTests class] context:@"context2" sizeRange:CKSizeRange()];
  XCTAssertNotEqualObjects(firstConfiguration, secondConfiguration);
}

@end
