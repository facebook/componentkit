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
+ (instancetype)newWithBlock:(void (^)(CKComponent *sender, id context))block
                   component:(CKComponent *)component;
- (void)testAction:(CKComponent *)sender context:(id)context;
@end
