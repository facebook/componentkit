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
#import "CKInternalHelpers.h"
#import <unordered_map>

// Need enough iterations for signal

#define TEST_ITERATIONS (1000 * 1000)

@interface test_abcdefghijklmnopq: NSObject
@end

@interface test_abcdefghijklmnopqr: NSObject
@end

@implementation test_abcdefghijklmnopq
@end

@implementation test_abcdefghijklmnopqr
@end

@interface CKComponentViewClassIdentifierPerfTests : XCTestCase
@end

@implementation CKComponentViewClassIdentifierPerfTests

- (void)testComponentViewClassInfo
{
  NSLog(@"Size of std::string: %ld", sizeof(std::string));
  NSLog(@"Size of std::CKComponentViewClassIdentifier: %ld", sizeof(CKComponentViewClassIdentifier));
}

- (void)testPerformanceWithStdString
{
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      std::string s = std::string(class_getName([UIView class]));
    }
  }];
}

- (void)testPerformanceWithStdStringLen22
{
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      std::string s = std::string(class_getName([test_abcdefghijklmnopq class]));
    }
  }];
}

- (void)testPerformanceWithStructLen22
{
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      CKComponentViewClassIdentifier identifier([test_abcdefghijklmnopq class]);
    }
  }];
}

- (void)testPerformanceWithStdStringLen23
{
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      std::string s = std::string(class_getName([test_abcdefghijklmnopqr class]));
    }
  }];
}

- (void)testPerformanceWithStructLen23
{
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      CKComponentViewClassIdentifier identifier([test_abcdefghijklmnopqr class]);
    }
  }];
}

- (void)testPerformanceWithStruct
{
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      CKComponentViewClassIdentifier identifier([UIView class]);
    }
  }];
}

- (void)testPerformanceWithStdStringWithSelector
{
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      std::string s = std::string(class_getName([test_abcdefghijklmnopqr class])) + sel_getName(@selector(description));
    }
  }];
}

- (void)testPerformanceWithStructWithSelector
{
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      CKComponentViewClassIdentifier identifier([test_abcdefghijklmnopqr class], @selector(description));
    }
  }];
}

- (void)testPerformanceWithStdStringWithFunctionPointer
{
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      std::string s = std::string(CKStringFromPointer(0));
    }
  }];
}

- (void)testPerformanceWithStructWithFunctionPointer
{
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      CKComponentViewClassIdentifier identifier((UIView *(*)(void))0);
    }
  }];
}

- (void)testPerformanceAddMapWithStringKey
{
  const std::string key = "some_key";
  __block std::unordered_map<std::string, NSObject *> map;
  
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      map[key] = nullptr;
    }
  }];
}

- (void)testPerformanceAddMapWithStructKey
{
  const CKComponentViewClassIdentifier key = {[UIView class]};
  __block std::unordered_map<CKComponentViewClassIdentifier, NSObject *> map;
  
  [self measureBlock:^{
    for (auto i = 0; i < TEST_ITERATIONS; i++) {
      map[key] = nullptr;
    }
  }];
}

- (void)testPerformanceGetRemoveFromMapWithStringKey
{
  NSObject *value = @"Hello World";
  const std::string key = "some_key";
  __block std::unordered_map<std::string, NSObject *> map;
  
  __block Class *classes = nullptr;
  
  auto numClasses = objc_getClassList(NULL, 0);
  
  if (numClasses > 0 ) {
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
  }
  
  for (auto i = 0; i < numClasses; i++) {
    map[class_getName(classes[i])] = value;
  }
  
  std::srand(197);
  
  [self measureBlock:^{
    for (auto j = 0; j < 10; j++) {
      auto index = std::rand() % numClasses;
      auto theClass = &classes[index];
      auto name = object_getClassName(*theClass);
      
      for (auto i = 0; i < TEST_ITERATIONS / 100; i++) {
        map.erase(name);
        map[name] = value;
      }
    }
  }];
  
  free(classes);
}

- (void)testPerformanceGetFromMapWithStructKey
{
  NSObject *value = @"Hello World";
  __block std::unordered_map<CKComponentViewClassIdentifier, NSObject *> map;
  
  __block Class *classes = nullptr;
  
  auto numClasses = objc_getClassList(NULL, 0);
  
  if (numClasses > 0 ) {
    classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
  }
  
  for (auto i = 0; i < numClasses; i++) {
    map[{classes[i]}] = value;
  }
  
  std::srand(197);
  
  [self measureBlock:^{
    for (auto j = 0; j < 10; j++) {
      auto index = std::rand() % numClasses;
      auto theClass = &classes[index];
      
      for (auto i = 0; i < TEST_ITERATIONS / 100; i++) {
        map.erase({*theClass});
        map[{*theClass}] = value;
      }
    }
  }];
  
  free(classes);
}

- (void)testPerformanceGetRemoveFromMapWithStringKeyWithSelector
{
  NSObject *value = @"Hello World";
  const std::string key = "some_key";
  __block std::unordered_map<std::string, NSObject *> map;
  
  __block Class *classes = nullptr;
  
  auto numClasses = objc_getClassList(NULL, 0);
  
  if (numClasses > 0 ) {
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
  }
  
  for (auto i = 0; i < numClasses; i++) {
    map[std::string(class_getName(classes[i])) + "-" + sel_getName(@selector(description))] = value;
  }
  
  std::srand(197);
  
  [self measureBlock:^{
    for (auto j = 0; j < 10; j++) {
      auto index = std::rand() % numClasses;
      auto theClass = &classes[index];
      auto name = std::string(class_getName(*theClass)) + "-" + sel_getName(@selector(description));
      
      for (auto i = 0; i < TEST_ITERATIONS / 100; i++) {
        map.erase(name);
        map[name] = value;
      }
    }
  }];
  
  free(classes);
}

- (void)testPerformanceGetFromMapWithStructKeyWithSelector
{
  NSObject *value = @"Hello World";
  __block std::unordered_map<CKComponentViewClassIdentifier, NSObject *> map;
  
  __block Class *classes = nullptr;
  
  auto numClasses = objc_getClassList(NULL, 0);
  
  if (numClasses > 0 ) {
    classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
  }
  
  for (auto i = 0; i < numClasses; i++) {
    map[{classes[i], @selector(description)}] = value;
  }
  
  std::srand(197);
  
  [self measureBlock:^{
    for (auto j = 0; j < 10; j++) {
      auto index = std::rand() % numClasses;
      auto key = CKComponentViewClassIdentifier {classes[index], @selector(description)};
      
      for (auto i = 0; i < TEST_ITERATIONS / 100; i++) {
        map.erase(key);
        map[key] = value;
      }
    }
  }];
  
  free(classes);
}

@end
