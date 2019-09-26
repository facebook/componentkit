/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <XCTest/XCTest.h>

#import <ComponentKit/CKComponent+UIView.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentDelegateAttribute.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKCompositeComponent.h>


@interface CKDetectScrollComponent : CKCompositeComponent <UIScrollViewDelegate>
@property (nonatomic, assign) BOOL receivedScroll;
@end

@interface CKComponentGestureActionsTests : XCTestCase
@end

@interface CKComponentDelegateAttributeTests : XCTestCase
@end

@implementation CKComponentDelegateAttributeTests

- (void)testApplicationApplies
{
  CKComponentViewAttributeValue attr = CKComponentDelegateAttribute(@selector(setDelegate:), {
    @selector(scrollViewDidScroll:)
  });

  UIScrollView *scrollView = [[UIScrollView alloc] init];

  attr.first.applicator(scrollView, attr.second);
  XCTAssertNotNil(scrollView.delegate, @"Expected delegate to be set");

  attr.first.unapplicator(scrollView, attr.second);
  XCTAssertNil(scrollView.delegate, @"Expected delegate to be unset");
}

static UIScrollView *findScrollView(UIView *v)
{
  if ([v isKindOfClass:[UIScrollView class]]) {
    return (UIScrollView *)v;
  } else {
    for (UIView *sub in v.subviews) {
      return findScrollView(sub);
    }
  }
  return nil;
};


- (void)testProxiedEventsProxy
{
  CKDetectScrollComponent *hierarchy =
  [CKDetectScrollComponent
   newWithComponent:CK::ComponentBuilder()
                        .viewClass([UIScrollView class])
                        .attribute(CKComponentDelegateAttribute(@selector(setDelegate:), {
                         @selector(scrollViewDidScroll:),
                       }))
                        .build()];


  CKComponentLayout layout = [hierarchy layoutThatFits:{} parentSize:{NAN, NAN}];

  UIView *container = [UIView new];
  NSSet *mounted = CKMountComponentLayout(layout, container, nil, nil).mountedComponents;

  XCTAssertFalse(hierarchy.receivedScroll, @"Should not have triggered yet");

  UIScrollView *scroll = findScrollView(container);

  scroll.contentOffset = CGPointMake(0, 100);

  XCTAssertTrue(hierarchy.receivedScroll, @"Should have recived scroll event");

  // Temporary hack because there's not a good way to unmount components. An assert fires otherwise.
  // TODO: CKComponentUnmount(mounted);
  [mounted makeObjectsPerformSelector:@selector(unmount)];

  CKDetectScrollComponent *noScrollHierarchy =
  [CKDetectScrollComponent
   newWithComponent:CK::ComponentBuilder()
                        .viewClass([UIScrollView class])
                        .attribute(CKComponentDelegateAttribute(@selector(setDelegate:), {}))
                        .build()];

  layout = [noScrollHierarchy layoutThatFits:{} parentSize:{NAN, NAN}];

  CKMountComponentLayout(layout, container, nil, nil);

  XCTAssertFalse(noScrollHierarchy.receivedScroll, @"Should not have triggered yet");
  hierarchy.receivedScroll = NO;

  scroll.contentOffset = CGPointMake(0, 100);

  XCTAssertFalse(noScrollHierarchy.receivedScroll, @"Should not have triggered because we don't want scroll events.");
  XCTAssertFalse(hierarchy.receivedScroll, @"Should not have triggered on old hierarchy either.");
}

- (void)testProxiedEventsProxyThrowsAssertionButDoesNotCrashWhenUnmounted
{
  CKDetectScrollComponent *hierarchy =
  [CKDetectScrollComponent
   newWithComponent:CK::ComponentBuilder()
                        .viewClass([UIScrollView class])
                        .attribute(CKComponentDelegateAttribute(@selector(setDelegate:), {
                         @selector(scrollViewDidScroll:),
                       }))
                        .build()];


  CKComponentLayout layout = [hierarchy layoutThatFits:{} parentSize:{NAN, NAN}];

  UIView *container = [UIView new];
  NSSet *mounted = CKMountComponentLayout(layout, container, nil, nil).mountedComponents;

  XCTAssertFalse(hierarchy.receivedScroll, @"Should not have triggered yet");

  UIScrollView *scroll = findScrollView(container);

  CKUnmountComponents(mounted);

  @try {
    // We have an assertion that may throw an exception depending on build flags. We don't want to assert that it throws
    // but we do want to make sure we don't crash, so we catch it and ignore the results.
    scroll.contentOffset = CGPointMake(0, 100);
  } @catch (NSException *exception) { }

  XCTAssertFalse(hierarchy.receivedScroll, @"Should not have recived scroll event");

  // Un-set the delegate since deallocation will trigger a scroll event, which will throw the same assertion as we are
  // catching above.
  scroll.delegate = nil;
}

@end


@implementation CKDetectScrollComponent

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  _receivedScroll = YES;
}

@end
