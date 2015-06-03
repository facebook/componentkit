// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKMRootViewController.h"
#import "CKMSampleComponentProvider.h"

#import "CKMTableCellComponentProvider.h"

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentHostingView.h>
#import <ComponentKit/CKComponentHostingViewDelegate.h>
#import <ComponentKit/CKComponentSizeRangeProviding.h>
#import <ComponentKit/CKComponentFlexibleSizeRangeProvider.h>

#import <ComponentKit/CKTransactionalComponentDataSourceChangeset.h>

#import <ComponentKit/CKNSTableViewDataSource.h>

#define SHOW_TABLEVIEW 0

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

  // Build up a nice changeset with our rows
  NSMutableArray *data = [NSMutableArray array];
  for (NSInteger i = 0; i<800; i++) {
    NSMutableString *ms = [NSMutableString string];
    NSInteger idx = i % ('z' - 'a' + 1);
    char c = 'a' + (char)idx;
    // Repeat idx times
    for (NSInteger j = 0; j <= idx; j++) {
      [ms appendFormat:@" %c", c];
    }
    [data addObject:[ms copy]];
  }



  self.hostingView.model = data;

  self.hostingView.frame = self.view.bounds;
  self.hostingView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
  [self.view addSubview:self.hostingView];
}

@end
