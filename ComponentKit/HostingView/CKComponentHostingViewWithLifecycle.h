// (c) Facebook, Inc. and its affiliates. Confidential and proprietary.

#import <ComponentKit/CKComponentHostingView.h>

@protocol CKComponentHostingViewWithLifecycle

/** Appearance events to be funneled to the component tree. */
- (void)hostingViewWillAppear;
- (void)hostingViewDidDisappear;

@end
