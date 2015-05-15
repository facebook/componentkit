// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKMRootViewController.h"
#import "CKMSampleComponentProvider.h"

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentHostingView.h>
#import <ComponentKit/CKComponentHostingViewDelegate.h>
#import <ComponentKit/CKComponentSizeRangeProviding.h>
#import <ComponentKit/CKComponentFlexibleSizeRangeProvider.h>

@interface CKMRootViewController ()

@property (nonatomic, strong) CKComponentHostingView *hostingView;

@end

@implementation CKMRootViewController

- (void)loadView
{
  self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 480, 200)];
  
  self.hostingView = [[CKComponentHostingView alloc] initWithComponentProvider:[CKMSampleComponentProvider class]
                                                             sizeRangeProvider:nil
                                                                       context:self];
  
  self.hostingView.model = @"FBStackLayoutComponent with custom CKMTextLabelComponent and CKMButtonComponent components in OS X app!!!!1111";

  self.hostingView.frame = self.view.bounds;
  self.hostingView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
  [self.view addSubview:self.hostingView];
}

@end
