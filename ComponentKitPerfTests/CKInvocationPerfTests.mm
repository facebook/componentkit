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

#define TEST_ITERATIONS (1000 * 1000)


using SetObjectValue = void(*)(id obj, id value);
using SetObjectBool = void(*)(id obj, BOOL value);

static void setBackgroundColor(id obj, id value) {
  [obj setBackgroundColor:value];
}

static void setUserInteractionEnabled(id obj, BOOL value) {
  [obj setUserInteractionEnabled:value];
}

static id getView() {
  return [[UIView alloc] init];
}

static SEL getUserInteractionEnabledSelector() {
  return @selector(setUserInteractionEnabled:);
}

@interface CKInvocationPerfTests : XCTestCase
@end

@implementation CKInvocationPerfTests

- (void)testSetBackgroundColorWithPerformSelector
{
  id view = getView();
  SEL sel = @selector(setBackgroundColor:);
  UIColor *color = [UIColor clearColor];
  
  [self measureBlock:^{
    for (int i = 0; i < TEST_ITERATIONS; i++) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [view performSelector:sel withObject:color];
#pragma clang diagnostic pop
    }
  }];
}

- (void)testSetBackgroundColorWithFunc
{
  id view = getView();
  UIColor *color = [UIColor clearColor];
  
  SetObjectValue func = setBackgroundColor;
  
  [self measureBlock:^{
    for (int i = 0; i < TEST_ITERATIONS; i++) {
      func(view, color);
    }
  }];
}

- (void)testSetBackgroundColorWithMethodCall
{
  id view = getView();
  UIColor *color = [UIColor clearColor];
  
  [self measureBlock:^{
    for (int i = 0; i < TEST_ITERATIONS; i++) {
      [view setBackgroundColor:color];
    }
  }];
}

- (void)testSetUserInteractionEnabledWithInvocation
{
  id view = getView();
  NSNumber *value = @(YES);
  
  SEL sel = @selector(setUserInteractionEnabled:);
  NSMethodSignature *sig = [view methodSignatureForSelector:sel];
  
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
  [invocation setSelector:sel];
  
  [self measureBlock:^{
    for (int i = 0; i < TEST_ITERATIONS; i++) {
      BOOL boolValue = [value boolValue];
      
      [invocation setArgument:&boolValue atIndex:2];
      [invocation invokeWithTarget:view];
    }
  }];
}

- (void)testSetUserInteractionEnabledWithFunc
{
  id view = getView();
  NSNumber *value = @(YES);
  
  SetObjectBool func = setUserInteractionEnabled;
  
  [self measureBlock:^{
    for (int i = 0; i < TEST_ITERATIONS; i++) {
      BOOL boolValue = [value boolValue];
      func(view, boolValue);
    }
  }];
}

- (void)testSetUserInteractionEnabledWithMethodCall
{
  id view = getView();
  SEL sel = getUserInteractionEnabledSelector();
  NSNumber *value = @(YES);
  
  [self measureBlock:^{
    for (int i = 0; i < TEST_ITERATIONS; i++) {
      if (sel == @selector(setUserInteractionEnabled:)) {
        BOOL boolValue = [value boolValue];
        [view setUserInteractionEnabled:boolValue];
      }
    }
  }];
}

@end
