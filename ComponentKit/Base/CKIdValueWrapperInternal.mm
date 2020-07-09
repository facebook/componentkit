/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKIdValueWrapperInternal.h"

#import <objc/runtime.h>

// WARNING: This code runs with -fno-objc-arc. There's no automatic reference counting in this .mm
// because of `class_createInstance` and the manual management of extra bytes.

@implementation CKIdValueWrapper {
  CKIdValueWrapperComparatorType _comparator;
  CKIdValueWrapperReleaserType _releaser;
}

- (instancetype)initWithValue:(void *const)value assigner:(CKIdValueWrapperAssignerType)assigner releaser:(CKIdValueWrapperReleaserType)releaser comparator:(CKIdValueWrapperComparatorType)comparator {
  if (self = [super init]) {
    _comparator = comparator;
    _releaser = releaser;
    if (assigner != nil) {
      assigner(object_getIndexedIvars(self), value);
    }
  }

  return self;
}

- (BOOL)isEqual:(id)object {
  if ([super isEqual:object]) {
    return YES;
  }

  if (_comparator != nullptr && [object isMemberOfClass:CKIdValueWrapper.class]) {
    return _comparator(object_getIndexedIvars(self), object_getIndexedIvars(object));
  } else {
    return NO;
  }
}

- (void)dealloc {
  // Call the dtor on the value
  _releaser(object_getIndexedIvars(self));

  [super dealloc];
}

@end

CKIdValueWrapper *CKIdValueWrapperAlloc(NSUInteger extraBytes) {
  return class_createInstance(CKIdValueWrapper.class, extraBytes);
}

void *CKIdValueWrapperGetUntyped(CKIdValueWrapper *object) {
  return object_getIndexedIvars(object);
}
