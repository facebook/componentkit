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
#import <ComponentKit/CKComponentSubclass.h>

@interface CKTypedPropsComponent ()

+ (instancetype)newWithPropsStruct:(const CKTypedComponentStruct &)props
                              view:(const CKComponentViewConfiguration &)view
                              size:(const CKComponentSize &)size;

+ (CKComponent *)renderWithProps:(const CKTypedComponentStruct &)props
                           state:(id)state
                            view:(const CKComponentViewConfiguration &)view
                            size:(const CKComponentSize &)size;

@property (nonatomic, assign, readonly) CKTypedComponentStruct props;
@property (nonatomic, strong, readonly) id state;

@end
