/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTestActionComponent.h"

@implementation CKTestActionComponent
{
  void (^_block)(CKComponent *, id);
  void (^_secondBlock)(CKComponent *, id, id);
  void (^_primitiveArgumentBlock)(CKComponent *, int);
  void (^_noArgumentBlock)(CKComponent *sender);
  void (^_cppArgumentBlock)(CKComponent *, std::vector<std::string>);
}

+ (instancetype)newWithSingleArgumentBlock:(void (^)(CKComponent *sender, id context))singleArgumentBlock
                       secondArgumentBlock:(void (^)(CKComponent *sender, id obj1, id obj2))secondArgumentBlock
                    primitiveArgumentBlock:(void (^)(CKComponent *sender, int value))primitiveArgumentBlock
                           noArgumentBlock:(void (^)(CKComponent *sender))noArgumentBlock
                                 component:(CKComponent *)component
{
  CKTestActionComponent *c = [super newWithComponent:component];
  if (c) {
    c->_block = singleArgumentBlock;
    c->_secondBlock = secondArgumentBlock;
    c->_primitiveArgumentBlock = primitiveArgumentBlock;
    c->_noArgumentBlock = noArgumentBlock;
  }
  return c;
}

+ (instancetype)newWithCppArgumentBlock:(void (^)(CKComponent *sender, std::vector<std::string> vec))block
                              component:(CKComponent *)component
{
  CKTestActionComponent *c = [super newWithComponent:component];
  if (c) {
    c->_cppArgumentBlock = block;
  }
  return c;
}

- (void)testAction:(CKComponent *)sender context:(id)context
{
  _block(sender, context);
}

- (void)testAction2:(CKComponent *)sender context1:(id)context1 context2:(id)context2
{
  _secondBlock(sender, context1, context2);
}

- (void)testPrimitive:(CKComponent *)sender integer:(int)integer
{
  _primitiveArgumentBlock(sender, integer);
}

- (void)testNoArgumentAction:(CKComponent *)sender
{
  _noArgumentBlock(sender);
}

- (void)testCppArgumentAction:(CKComponent *)sender vector:(std::vector<std::string>)vec
{
  _cppArgumentBlock(sender, vec);
}

@end
