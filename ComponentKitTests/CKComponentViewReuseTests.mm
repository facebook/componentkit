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

#import "ComponentViewManager.h"
#import "ComponentViewReuseUtilities.h"
#import "CKComponent.h"
#import "CKComponentInternal.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentProvider.h"
#import "CKCompositeComponent.h"

@interface CKComponentViewReuseTests : XCTestCase <CKComponentProvider>
@end

/** Injects a view not controlled by components and specifies its children should be mounted inside it. */
@interface CKViewInjectingComponent : CKCompositeComponent
@end

/** Doesn't actually do anything, just provides a BOOL for storage. */
@interface CKReuseAwareView : UIView
@property (nonatomic, assign, getter=isInReusePool) BOOL inReusePool;
@end

using namespace CK::Component;

@implementation CKComponentViewReuseTests

static UIView *viewFactory()
{
  return [[UIView alloc] init];
}

- (void)testThatRecyclingViewWithoutEnteringReusePoolDoesNotCallReuseBlocks
{
  CKComponent *component =
  [CKComponent
   newWithView:{
     {
       &viewFactory,
       ^(UIView *v){ XCTFail(@"Didn't expect to have didEnterReusePool called"); },
       ^(UIView *v){ XCTFail(@"Didn't expect to have willLeaveReusePool called"); }
     },
     {}
   }
   size:{}];

  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *subview;
  {
    ViewManager m(container);
    subview = m.viewForConfiguration([component class], [component viewConfiguration]);
  }

  {
    ViewManager m(container);
    XCTAssertTrue(subview == m.viewForConfiguration([component class], [component viewConfiguration]), @"Expected to receive recycled view");
  }
}

- (void)testThatViewEnteringReusePoolTriggersCallToDidEnterReusePool
{
  __block UIView *viewThatEnteredReusePool = nil;
  CKComponent *firstComponent =
  [CKComponent
   newWithView:{
     {
       &viewFactory,
       ^(UIView *v){ viewThatEnteredReusePool = v; },
       ^(UIView *v){ XCTFail(@"Didn't expect to have willLeaveReusePool called"); }
     },
     {}
   }
   size:{}];

  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *createdView;
  {
    ViewManager m(container);
    createdView = m.viewForConfiguration([firstComponent class], [firstComponent viewConfiguration]);
  }

  CKComponent *secondComponent = [CKComponent newWithView:{[UIImageView class], {}} size:{}];
  {
    ViewManager m(container);
    (void)m.viewForConfiguration([secondComponent class], [secondComponent viewConfiguration]);
  }

  XCTAssertTrue(viewThatEnteredReusePool == createdView, @"Expected created view %@ to enter pool but got %@",
               createdView, viewThatEnteredReusePool);
}

- (void)testThatViewLeavingReusePoolTriggersCallToWillLeaveReusePool
{
  __block UIView *viewThatEnteredReusePool = nil;
  __block BOOL calledWillLeaveReusePool = NO;
  CKComponent *firstComponent =
  [CKComponent
   newWithView:{
     {
       &viewFactory,
       ^(UIView *v){ viewThatEnteredReusePool = v; },
       ^(UIView *v){
         XCTAssertTrue(v == viewThatEnteredReusePool, @"Expected %@ but got %@", viewThatEnteredReusePool, v);
         calledWillLeaveReusePool = YES;
       }
     },
     {}
   }
   size:{}];

  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  {
    ViewManager m(container);
    (void)m.viewForConfiguration([firstComponent class], [firstComponent viewConfiguration]);
  }

  CKComponent *secondComponent = [CKComponent newWithView:{[UIImageView class]} size:{}];
  {
    ViewManager m(container);
    (void)m.viewForConfiguration([secondComponent class], [secondComponent viewConfiguration]);
  }

  {
    ViewManager m(container);
    (void)m.viewForConfiguration([firstComponent class], [firstComponent viewConfiguration]);
  }

  XCTAssertTrue(calledWillLeaveReusePool, @"Expected to call willLeaveReusePool when recycling view");
}

- (void)testThatHidingParentViewTriggersCallToDidEnterReusePool
{
  __block UIView *viewThatEnteredReusePool = nil;

  CKComponent *innerComponent =
  [CKComponent
   newWithView:{
     {
       &viewFactory,
       ^(UIView *v){ viewThatEnteredReusePool = v; },
       ^(UIView *v){ XCTFail(@"Didn't expect willLeaveReusePool"); }
     },
     {}
   }
   size:{}];

  CKComponent *firstComponent =
  [CKCompositeComponent
   newWithView:{[UIView class], {}}
   component:innerComponent];

  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *topLevelView;
  {
    ViewManager m(container);
    topLevelView = m.viewForConfiguration([firstComponent class], [firstComponent viewConfiguration]);
    {
      ViewManager m2(topLevelView);
      (void)m2.viewForConfiguration([innerComponent class], [innerComponent viewConfiguration]);
    }
  }

  CKComponent *secondComponent = [CKComponent newWithView:{[UIImageView class]} size:{}];
  {
    ViewManager m(container);
    (void)m.viewForConfiguration([secondComponent class], [secondComponent viewConfiguration]);
  }

  XCTAssertNotNil(viewThatEnteredReusePool, @"Expected view to enter reuse pool when its parent was hidden");
  XCTAssertFalse(viewThatEnteredReusePool.hidden, @"View that entered pool should not be hidden since its parent was");
  XCTAssertTrue(topLevelView.hidden, @"Top-level view should be hidden for reuse");
}

- (void)testThatUnhidingParentViewButLeavingChildViewHiddenLeavesViewInReusePool
{
  __block UIView *viewThatEnteredReusePool = nil;

  CKComponent *innerComponent =
  [CKComponent
   newWithView:{
     {
       &viewFactory,
       ^(UIView *v){ viewThatEnteredReusePool = v; },
       ^(UIView *v){ XCTFail(@"Didn't expect willLeaveReusePool"); }
     },
     {}
   }
   size:{}];

  CKComponent *firstComponent =
  [CKCompositeComponent
   newWithView:{[UIView class], {}}
   component:innerComponent];

  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *topLevelView;
  {
    ViewManager m(container);
    topLevelView = m.viewForConfiguration([firstComponent class], [firstComponent viewConfiguration]);
    {
      ViewManager m2(topLevelView);
      (void)m2.viewForConfiguration([innerComponent class], [innerComponent viewConfiguration]);
    }
  }

  CKComponent *secondComponent = [CKComponent newWithView:{[UIImageView class]} size:{}];
  {
    ViewManager m(container);
    (void)m.viewForConfiguration([secondComponent class], [secondComponent viewConfiguration]);
  }

  XCTAssertNotNil(viewThatEnteredReusePool, @"Expected view to enter reuse pool when its parent was hidden");
  XCTAssertFalse(viewThatEnteredReusePool.hidden, @"View that entered pool should not be hidden since its parent was");

  CKComponent *thirdComponent =
  [CKCompositeComponent
   newWithView:{[UIView class], {}}
   component:[CKComponent newWithView:{} size:{}]];
  {
    ViewManager m(container);
    UIView *newestTopLevelView = m.viewForConfiguration([thirdComponent class], [thirdComponent viewConfiguration]);
    XCTAssertTrue(newestTopLevelView == topLevelView, @"Expected top level view to be reused");
    {
      ViewManager m2(newestTopLevelView);
    }
  }

  XCTAssertTrue(viewThatEnteredReusePool.hidden, @"View should now be hidden since its parent was unhidden");
  // The key here is that we did *not* receive any notifications about leaving the pool since it remained in the pool,
  // even though its parent was unhidden and it was hidden.
}

- (void)testThatComponentThatInjectsAnIntermediateViewNotControlledByComponentsDoesNotBreakViewReuseForItsSubviews
{
  UIView *rootView = [[UIView alloc] init];

  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [clm updateWithState:[clm prepareForUpdateWithModel:@NO constrainedSize:{{0,0}, {100, 100}} context:nil]];
  [clm attachToView:rootView];

  // Find the reuse aware view
  CKReuseAwareView *reuseAwareView = [[[[[[rootView subviews] firstObject] subviews] firstObject] subviews] firstObject];
  XCTAssertFalse(reuseAwareView.inReusePool, @"Shouldn't be in reuse pool now, it's just been mounted");

  // Update to a totally different component so that the reuse aware view's parent should be hidden
  [clm updateWithState:[clm prepareForUpdateWithModel:@YES constrainedSize:{{0,0}, {100, 100}} context:nil]];
  XCTAssertTrue(reuseAwareView.inReusePool, @"Should be in reuse pool as its parent is hidden by components");
}

static UIView *reuseAwareViewFactory()
{
  return [[CKReuseAwareView alloc] init];
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  if ([(NSNumber *)model boolValue]) {
    return [CKComponent newWithView:{[UIView class]} size:{50, 50}];
  } else {
    return [CKViewInjectingComponent
            newWithComponent:
            [CKComponent
             newWithView:{
               {
                 &reuseAwareViewFactory,
                 ^(UIView *v){ ((CKReuseAwareView *)v).inReusePool = YES; },
                 ^(UIView *v){ ((CKReuseAwareView *)v).inReusePool = NO; }
               },
               {}
             }
             size:{}]];
  }
}

@end

@interface CKInjectingView : UIView
@property (nonatomic, strong, readonly) UIView *injectedView;
@end

@implementation CKInjectingView
- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _injectedView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addSubview:_injectedView];
  }
  return self;
}
- (void)layoutSubviews
{
  [super layoutSubviews];
  [_injectedView setFrame:{CGPointZero, [self bounds].size}];
}
@end

@implementation CKViewInjectingComponent

+ (instancetype)newWithComponent:(CKComponent *)component
{
  return [super newWithView:{[CKInjectingView class]} component:component];
}

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                      layout:(const CKComponentLayout &)layout
                              supercomponent:(CKComponent *)supercomponent
{
  const auto result = [super mountInContext:context layout:layout supercomponent:supercomponent];
  CKInjectingView *injectingView = (CKInjectingView *)result.contextForChildren.viewManager->view;
  return {
    .mountChildren = YES,
    .contextForChildren = result.contextForChildren.childContextForSubview(injectingView.injectedView, NO),
  };
}

@end

@implementation CKReuseAwareView
@end
