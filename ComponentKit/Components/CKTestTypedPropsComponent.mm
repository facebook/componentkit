/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTestTypedPropsComponent.h"

#import "CKTypedPropsComponentSubclass.h"
#import "CKLabelComponent.h"

@implementation CKTestTypedPropsComponent

+ (instancetype)newWithProps:(const CKTestTypedPropsComponentProps &)props
                        view:(const CKComponentViewConfiguration &)view
                        size:(const CKComponentSize &)size
{
  return [self newWithPropsStruct:props
                             view:view
                             size:size];
}

+ (CKComponent *)renderWithProps:(const CKTypedComponentStruct &)p
                           state:(id)state
                            view:(const CKComponentViewConfiguration &)view
                            size:(const CKComponentSize &)size
{
  const CKTestTypedPropsComponentProps props = p;
  return [CKLabelComponent
          newWithLabelAttributes:{
            .string = props.string,
            .font = props.font
          }
          viewAttributes:*view.attributes()
          size:size];
}

@end
