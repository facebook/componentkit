/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKMTableCellComponentProvider.h"

@implementation CKMTableCellComponentProvider

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  NSString *string = (NSString *)model;

  return [CKStackLayoutComponent
          newWithView:{}
          size:{.width = 320}
          style:{CKStackLayoutDirectionHorizontal}
          children:{
            {[CKMTextLabelComponent
             newWithTextAttributes:{
               .text = string,
               .color = [NSColor secondaryLabelColor],
               .backgroundColor = [NSColor clearColor],
             }
             viewAttributes:{}
             size:{
               .maxWidth = 150,
             }]},
            {[CKMButtonComponent
              newWithTitle: @"Do Something"
             target:nil
             action:nil]},
          }];

}


@end
