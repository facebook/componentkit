/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKTypedPropsComponent.h>

struct CKTestTypedPropsComponentProps {
  CKRequiredProp<NSString *> string;
  UIFont *font;
};

@interface CKTestTypedPropsComponent : CKTypedPropsComponent

+ (instancetype)newWithProps:(const CKTestTypedPropsComponentProps &)props
                        view:(const CKComponentViewConfiguration &)view
                        size:(const CKComponentSize &)size;

@end
