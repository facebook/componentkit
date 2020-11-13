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
  void *_data;
}

- (instancetype)initWithValue:(void *const)value
                     assigner:(CKIdValueWrapperAssignerType)assigner
                     releaser:(CKIdValueWrapperReleaserType)releaser
                   comparator:(CKIdValueWrapperComparatorType)comparator
                dataAlignment:(NSUInteger)dataAlignment {
  if (self = [super init]) {
    _data = _dataPointerValue(self, dataAlignment);
    _comparator = comparator;
    _releaser = releaser;
    if (assigner != nil) {
      assigner(_data, value);
    }
  }

  return self;
}

- (BOOL)isEqual:(id)object {
  if ([super isEqual:object]) {
    return YES;
  }

  if (_comparator != nullptr && [object isMemberOfClass:CKIdValueWrapper.class]) {
    return _comparator(_data, ((CKIdValueWrapper*)object)->_data);
  } else {
    return NO;
  }
}

- (void*)data {
  return _data;
}

- (void)dealloc {
  // Call the dtor on the value
  _releaser(_data);

  [super dealloc];
}

static void *_dataPointerValue(id instance, NSUInteger dataAlignment) {
  // `object_getIndexedIvars` returns a pointer size aligned pointer.
  // If the alignment of the data to store is greater than sizeof(void*),
  // adjust it. This assumes more space than necessary was requested.
  void* untypedUnalignedData = object_getIndexedIvars(instance);
  const auto unalignedData = reinterpret_cast<uintptr_t>(untypedUnalignedData);
  const auto remainder = unalignedData % dataAlignment;
  const auto delta = remainder != 0 ? dataAlignment - remainder : 0;
  return reinterpret_cast<void*>(unalignedData + delta);
}

@end

CKIdValueWrapper *CKIdValueWrapperAlloc(NSUInteger extraBytes, NSUInteger dataAlignment) {
  // Request more space if dataAlignment is greater than the guaranteed pointer size returned by
  // `object_getIndexedIvars` so we have enough space to adjust it.
  const auto alignmentPadding = (dataAlignment > sizeof(void *) ? dataAlignment - sizeof(void*) : 0);
  return class_createInstance(CKIdValueWrapper.class, extraBytes + alignmentPadding);
}
