// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKMSampleComponentProvider.h"

#import "CKMButtonComponent.h"
#import "CKMTextLabelComponent.h"
#import <ComponentKit/CKStackLayoutComponent.h>

@implementation CKMSampleComponentProvider

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  NSString *string = (NSString *)model;
  
  return [CKStackLayoutComponent
          newWithView:{}
          size:{}
          style:{
            .direction = CKStackLayoutDirectionVertical,
            .alignItems = CKStackLayoutAlignItemsStretch,
            .spacing = 5.0,
          }
          children:{
            {[CKMTextLabelComponent
              newWithTextAttributes:{
                .text = string,
                .backgroundColor = [NSColor whiteColor]}
              viewAttributes:{}
              size:{}],
              .flexGrow = YES, .flexBasis = 0.0},
            
            {[CKStackLayoutComponent
              newWithView:{}
              size:{}
              style:{
                .direction = CKStackLayoutDirectionHorizontal,
              }
              children:{
                {[CKMButtonComponent
                  newWithTitle:@"Flexible width"
                  target:nil
                  action:nil], .flexGrow = YES},
                {[CKMButtonComponent
                  newWithTitle:@"Fixed width"
                  target:nil
                  action:nil]},
              }]}
          }];
}

@end
