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

- (void)testConfigurationEquality {
  CKDataSourceConfiguration *firstConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:@"context"
                                                             sizeRange:CKSizeRange()];
  CKDataSourceConfiguration *secondConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:@"context"
                                                             sizeRange:CKSizeRange()];
  XCTAssertEqualObjects(firstConfiguration, secondConfiguration);
}

// Temporarily disabled.
// We convert our Function Pointers into blocks (which we don't compare)
// Once the ComponentProvider API is dead, we can delete the block and do this correctly.
- (void)disable_test_WhenComponentProvidersAreDifferent_NotEqual {
  auto const c1 = [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                                           context:@"context"
                                                                         sizeRange:CKSizeRange()];
  auto const c2 = [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:nullptr
                                                                           context:@"context"
                                                                         sizeRange:CKSizeRange()];
  XCTAssertNotEqualObjects(c1, c2);
}

- (void)test_WhenContextsAreDifferent_NotEqual {
  CKDataSourceConfiguration *firstConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:@"context"
                                                             sizeRange:CKSizeRange()];
  CKDataSourceConfiguration *secondConfiguration =
      [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                               context:@"context2"
                                                             sizeRange:CKSizeRange()];
  XCTAssertNotEqualObjects(firstConfiguration, secondConfiguration);
}

- (void)test_WhenSizeRangesAreDifferent_NotEqual {
  auto const c1 = [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                                           context:@"context"
                                                                         sizeRange:CKSizeRange()];
  auto const c2 = [[CKDataSourceConfiguration alloc] initWithComponentProviderFunc:ComponentProvider
                                                                           context:@"context"
                                                                         sizeRange:{CGSizeZero, {100, 100}}];
  XCTAssertNotEqualObjects(c1, c2);
}

static CKComponent *ComponentProvider(id<NSObject> m, id<NSObject> c)
{
  return nil;
}

@end
