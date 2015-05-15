// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKMAppDelegate.h"
#import "CKMRootViewController.h"

@interface CKMAppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation CKMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  self.window.contentViewController = [[CKMRootViewController alloc] init];
}

@end
