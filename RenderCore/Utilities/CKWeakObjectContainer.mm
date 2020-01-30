/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKWeakObjectContainer.h"

#import <objc/runtime.h>

#import "CKEqualityHelpers.h"

@implementation CKWeakObjectContainer

+ (instancetype)newWithObject:(id)object
{
  CKWeakObjectContainer *c = [super new];
  if (c) {
    c->_object = object;
  }
  return c;
}

- (BOOL)isEqual:(id)other
{
  if (other == self) {
    return YES;
  } else if (![other isKindOfClass:[self class]]) {
    return NO;
  } else {
    CKWeakObjectContainer *container = (CKWeakObjectContainer *)other;
    return CKObjectIsEqual(self->_object, container->_object);
  }
}

- (NSUInteger)hash
{
  return [self->_object hash];
}

@end

void ck_objc_setNonatomicAssociatedWeakObject(id container, void *key, id value)
{
  CKWeakObjectContainer *wrapper = [CKWeakObjectContainer newWithObject:value];
  objc_setAssociatedObject(container, key, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void ck_objc_setAssociatedWeakObject(id container, void *key, id value)
{
  CKWeakObjectContainer *wrapper = [CKWeakObjectContainer newWithObject:value];
  objc_setAssociatedObject(container, key, wrapper, OBJC_ASSOCIATION_RETAIN);
}

id ck_objc_getAssociatedWeakObject(id container, void *key)
{
  return [(CKWeakObjectContainer*) objc_getAssociatedObject(container, key) object];
}
