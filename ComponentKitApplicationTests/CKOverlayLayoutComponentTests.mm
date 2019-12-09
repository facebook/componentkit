/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentSnapshotTestCase/CKComponentSnapshotTestCase.h>

#import <ComponentKit/CKOverlayLayoutComponent.h>

static const CKSizeRange kSize = {{320, 320}, {320, 320}};

@interface CKOverlayTestView : UIView

@end

@interface CKOverlayLayoutComponentTests : CKComponentSnapshotTestCase

@end

@implementation CKOverlayLayoutComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testOverlay
{
  auto const c = CK::OverlayLayoutComponentBuilder()
  .component(CK::ComponentBuilder()
                 .viewClass([UIView class])
                 .backgroundColor([UIColor blueColor])
                 .build())
  .overlay(CK::ComponentBuilder()
               .viewClass([CKOverlayTestView class])
               .backgroundColor([UIColor colorWithWhite:1.0
                                                  alpha:0.6])
               .build())
  .build();

  CKSnapshotVerifyComponent(c, kSize, nil);
}

@end

@implementation CKOverlayTestView

- (id)initWithFrame:(CGRect)aRect
{
  self = [super initWithFrame:aRect];
  if (self) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20.0, 20.0)];
    v.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [v setBackgroundColor:[UIColor blackColor]];
    v.center = CGPointMake(aRect.size.width/2.0, aRect.size.height/2.0);
    [self addSubview:v];
  }
  return self;
}

@end
