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

#import "CKComponentInternal.h"
#import "CKComponentScope.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKStackLayoutComponent.h"

@interface CKComponentBoundsAnimationTests : XCTestCase
@end

@interface CKBoundsAnimationRecordingView : UIView
@property (nonatomic, readonly) BOOL animatedLastBoundsChange;
@end

@implementation CKBoundsAnimationRecordingView
- (void)setBounds:(CGRect)bounds
{
  [super setBounds:bounds];
  _animatedLastBoundsChange = ![CATransaction disableActions];
}
@end

@interface CKBoundsAnimationComponent : CKComponent
@end

@implementation CKBoundsAnimationComponent
+ (instancetype)newWithIdentifier:(NSNumber *)identifier
{
  CKComponentScope scope(self, identifier);
  return [super newWithView:{[CKBoundsAnimationRecordingView class]} size:{}];
}

- (CKComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(CKComponent *)previousComponent
{
  return {.duration = 0.5};
}
@end

@implementation CKComponentBoundsAnimationTests

- (void)testBoundsAnimationCorrectlyComputedWhenBuildingNewVersionOfComponent
{
  CKComponent *(^block)(void) = ^{
    return [CKBoundsAnimationComponent newWithIdentifier:@0];
  };
  const CKBuildComponentResult firstResult = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, block);
  const CKBuildComponentResult secondResult = CKBuildComponent(firstResult.scopeRoot, {}, block);
  XCTAssertEqual(secondResult.boundsAnimation.duration, 0.5);
}

- (void)testBoundsAnimationIsAppliedToViewsWhenUpdatingToNewVersionOfComponent
{
  CKComponent *(^block)(void) = ^{
    return [CKBoundsAnimationComponent newWithIdentifier:@0];
  };
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

  const CKBuildComponentResult firstResult = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, block);
  const CKComponentLayout firstLayout = [firstResult.component layoutThatFits:{{50, 50}, {50, 50}} parentSize:{}];
  NSSet *firstMountedComponents = CKMountComponentLayout(firstLayout, container);

  const CKBuildComponentResult secondResult = CKBuildComponent(firstResult.scopeRoot, {}, block);
  const CKComponentLayout secondLayout = [secondResult.component layoutThatFits:{{100, 100}, {100, 100}} parentSize:{}];
  NSSet *secondMountedComponents = CKMountComponentLayout(secondLayout, container);

  CKBoundsAnimationRecordingView *v = (CKBoundsAnimationRecordingView *)secondResult.component.viewContext.view;
  XCTAssertTrue(v.animatedLastBoundsChange);

  [firstMountedComponents makeObjectsPerformSelector:@selector(unmount)];
  [secondMountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testBoundsAnimationIsNotAppliedToNewlyCreatedViews
{
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

  const CKBuildComponentResult firstResult = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, ^{
    return [CKStackLayoutComponent
            newWithView:{}
            size:{}
            style:{.alignItems = CKStackLayoutAlignItemsStretch}
            children:{
              {[CKBoundsAnimationComponent newWithIdentifier:@0], .flexGrow = YES},
            }];
  });
  const CKComponentLayout firstLayout = [firstResult.component layoutThatFits:{{100, 100}, {100, 100}} parentSize:{}];
  NSSet *firstMountedComponents = CKMountComponentLayout(firstLayout, container);

  const CKBuildComponentResult secondResult = CKBuildComponent(firstResult.scopeRoot, {}, ^{
    return [CKStackLayoutComponent
            newWithView:{}
            size:{}
            style:{.alignItems = CKStackLayoutAlignItemsStretch}
            children:{
              {[CKBoundsAnimationComponent newWithIdentifier:@0], .flexGrow = YES},
              {[CKBoundsAnimationComponent newWithIdentifier:@1], .flexGrow = YES},
            }];
  });
  const CKComponentLayout secondLayout = [secondResult.component layoutThatFits:{{100, 100}, {100, 100}} parentSize:{}];
  NSSet *secondMountedComponents = CKMountComponentLayout(secondLayout, container);

  XCTAssertEqual([container.subviews count], 2u);
  XCTAssertTrue(((CKBoundsAnimationRecordingView *)container.subviews[0]).animatedLastBoundsChange);
  XCTAssertFalse(((CKBoundsAnimationRecordingView *)container.subviews[1]).animatedLastBoundsChange);

  [firstMountedComponents makeObjectsPerformSelector:@selector(unmount)];
  [secondMountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testBoundsAnimationIsNotAppliedWhenViewRecycledForComponentWithDistinctScopeFrameToken
{
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

  const CKBuildComponentResult firstResult = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, ^{
    return [CKBoundsAnimationComponent newWithIdentifier:@0];
  });
  const CKComponentLayout firstLayout = [firstResult.component layoutThatFits:{{50, 50}, {50, 50}} parentSize:{}];
  NSSet *firstMountedComponents = CKMountComponentLayout(firstLayout, container);

  const CKBuildComponentResult secondResult = CKBuildComponent(firstResult.scopeRoot, {}, ^{
    return [CKBoundsAnimationComponent newWithIdentifier:@1];
  });
  const CKComponentLayout secondLayout = [secondResult.component layoutThatFits:{{100, 100}, {100, 100}} parentSize:{}];
  NSSet *secondMountedComponents = CKMountComponentLayout(secondLayout, container);

  CKBoundsAnimationRecordingView *v = (CKBoundsAnimationRecordingView *)secondResult.component.viewContext.view;
  XCTAssertFalse(v.animatedLastBoundsChange);

  [firstMountedComponents makeObjectsPerformSelector:@selector(unmount)];
  [secondMountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

@end
