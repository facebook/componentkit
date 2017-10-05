/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKCompositeComponent.h>

@interface CKTestActionComponent : CKCompositeComponent
/** @param block Executed when "testAction:context:" is invoked on the component */
+ (instancetype)newWithSingleArgumentBlock:(void (^)(CKComponent *sender, id context))singleArgumentBlock
                       secondArgumentBlock:(void (^)(CKComponent *sender, id obj1, id obj2))secondArgumentBlock
                    primitiveArgumentBlock:(void (^)(CKComponent *sender, int value))primitiveArgumentBlock
                           noArgumentBlock:(void (^)(CKComponent *sender))noArgumentBlock
                                 component:(CKComponent *)component;
- (void)testAction:(CKComponent *)sender context:(id)context;
- (void)testAction2:(CKComponent *)sender context1:(id)context1 context2:(id)context2;
- (void)testPrimitive:(CKComponent *)sender integer:(int)integer;
- (void)testNoArgumentAction:(CKComponent *)sender;
- (void)testCppArgumentAction:(CKComponent *)sender vector:(std::vector<std::string>)vec;

+ (instancetype)newWithCppArgumentBlock:(void (^)(CKComponent *sender, std::vector<std::string> vec))block
                              component:(CKComponent *)component;

@end
