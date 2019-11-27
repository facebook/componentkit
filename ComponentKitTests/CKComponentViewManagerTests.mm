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

#import <ComponentKit/ComponentViewManager.h>
#import <ComponentKit/ComponentViewReuseUtilities.h>
#import <ComponentKit/CKCasting.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKCompositeComponent.h>

using CK::Component::ViewManager;

@interface CKComponentViewManagerTests : XCTestCase
@end

/** Overrides all subview related methods *except* addSubview: to throw. */
@interface CKAddSubviewOnlyView : UIView
@property (nonatomic, assign) NSUInteger numberOfSubviewsAdded;
@end

/** View provides `didEnterReusePool` callback */
@interface CKTestReusableView : UIView
@property (nonatomic, readonly, assign) BOOL isDidEnterReusePoolCalled;
- (void)didEnterReusePool;
@end

@implementation CKComponentViewManagerTests

- (void)testThatComponentViewManagerVendsRecycledView
{
  CKComponent *component = CK::ComponentBuilder()
                               .viewClass([UIView class])
                               .build();

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

- (void)testThatComponentViewManagerHidesViewIfItWasNotRecycled
{
  CKComponent *component = CK::ComponentBuilder()
                               .viewClass([UIView class])
                               .build();

  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *subview;
  {
    ViewManager m(container);
    subview = m.viewForConfiguration([component class], [component viewConfiguration]);
  }
  XCTAssertFalse(subview.hidden, @"Did not expect subview to be hidden when it is initially vended");

  {
    ViewManager m(container);
  }
  XCTAssertTrue(subview.hidden, @"Expected subview to be hidden since it was not vended from the ComponentViewManager");
}

static NSArray *arrayByPerformingBlock(NSArray *array, id (^block)(id))
{
  NSMutableArray *result = [NSMutableArray array];
  for (id obj in array) {
    id res = block(obj);
    if (res != nil) {
      [result addObject:res];
    }
  }
  return result;
}

- (void)testThatComponentViewManagerReordersViewsIfOrderSwapped
{
  CKComponent *imageView = CK::ComponentBuilder()
                               .viewClass([UIImageView class])
                               .build();
  CKComponent *button = CK::ComponentBuilder()
                            .viewClass([UIButton class])
                            .build();
  NSArray *actualClasses, *expectedClasses;

  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  {
    ViewManager m(container);
    m.viewForConfiguration([imageView class], [imageView viewConfiguration]);
    m.viewForConfiguration([button class], [button viewConfiguration]);
  }
  actualClasses = arrayByPerformingBlock([container subviews], ^id(id object) { return [object class]; });
  expectedClasses = @[[UIImageView class], [UIButton class]];
  XCTAssertEqualObjects(actualClasses, expectedClasses, @"Expected imageview then button");

  {
    ViewManager m(container);
    m.viewForConfiguration([button class], [button viewConfiguration]);
    m.viewForConfiguration([imageView class], [imageView viewConfiguration]);
  }
  actualClasses = arrayByPerformingBlock([container subviews], ^id(id object) { return [object class]; });
  expectedClasses = @[[UIButton class], [UIImageView class]];
  XCTAssertEqualObjects(actualClasses, expectedClasses, @"Expected button then image view");
}

- (void)testThatComponentViewManagerDoesNotUnnecessarilyReorderViews
{
  CKComponent *imageView = CK::ComponentBuilder()
                               .viewClass([UIImageView class])
                               .build();
  CKComponent *button = CK::ComponentBuilder()
                            .viewClass([UIButton class])
                            .build();

  CKAddSubviewOnlyView *container = [[CKAddSubviewOnlyView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  {
    ViewManager m(container);
    m.viewForConfiguration([imageView class], [imageView viewConfiguration]);
    m.viewForConfiguration([button class], [button viewConfiguration]);
  }
  {
    ViewManager m(container);
    m.viewForConfiguration([imageView class], [imageView viewConfiguration]);
    m.viewForConfiguration([button class], [button viewConfiguration]);
  }
  XCTAssertEqual(container.numberOfSubviewsAdded, 2u, @"Expected exactly two subviews to be added");
}

- (void)testThatGettingRecycledViewForComponentDoesNotRecycleViewWithDisjointAttributes
{
  CKComponent *bgColorComponent =
  CK::ComponentBuilder()
      .viewClass([UIView class])
      .backgroundColor([UIColor blueColor])
      .build();

  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *subview;

  {
    ViewManager m(container);
    subview = m.viewForConfiguration([bgColorComponent class], [bgColorComponent viewConfiguration]);
  }

  CKComponent *alphaComponent =
  CK::ComponentBuilder()
      .viewClass([UIView class])
      .alpha(0.5)
      .build();

  {
    ViewManager m(container);
    XCTAssertTrue(subview != m.viewForConfiguration([alphaComponent class], [alphaComponent viewConfiguration]), @"Did not expect to receive recycled view with a disjoint attribute set; it would have a blue background that is not reset");
    XCTAssertTrue(subview == m.viewForConfiguration([bgColorComponent class], [bgColorComponent viewConfiguration]), @"Did expect that the view would be recycled when requested with a matching attribute set");
  }
}

static UIView *imageViewFactory()
{
  return [[UIImageView alloc] init];
}

- (void)testThatGettingViewForViewComponentWithNilViewClassCallsClassMethodNewView
{
  CKComponentViewClass customClass(&imageViewFactory);
  CKComponent *testComponent = CK::ComponentBuilder()
                                   .viewClass(std::move(customClass))
                                   .build();
  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  ViewManager m(container);
  UIView *subview = m.viewForConfiguration([testComponent class], [testComponent viewConfiguration]);
  XCTAssertTrue([subview isKindOfClass:[UIImageView class]], @"Expected +newView to vend a UIImageView");
}

- (void)testThatViewsInViewPoolAreHiddenAndDidHideIsCalledInDescendantAfterHideAllIsCalledOnRootView
{
  CKComponent *childComponent =
  CK::ComponentBuilder()
      .viewClass({[CKTestReusableView class], @selector(didEnterReusePool), nil})
      .build();
  CKComponent *component =
  [CKCompositeComponent
   newWithView:{{[CKTestReusableView class], @selector(didEnterReusePool), nil}}
   component:childComponent];

  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  {
    ViewManager m1(container);
    const auto subview = m1.viewForConfiguration([component class], [component viewConfiguration]);
    {
      ViewManager m2(subview);
      m2.viewForConfiguration([childComponent class], [childComponent viewConfiguration]);
    }
  }

  // All subviews should be visible after view manager is reset
  NSInteger numberOfViewsVisible = 0;
  checkSubviewsAreHidden(container, NO, &numberOfViewsVisible);
  XCTAssertEqual(numberOfViewsVisible, 2);

  CK::Component::ViewReusePool::hideAll(container, nullptr);
  // Only views in the view pool of `container` are hidden since there is no need to `setHidden` for their descendant.
  NSInteger numberOfViewsHidden = 0;
  checkSubviewsAreHidden(container, YES, &numberOfViewsHidden);
  XCTAssertEqual(numberOfViewsHidden, 1);

  // Although `setHidden` is not needed to be called on all descendant, calling `didEnterReusePool` is necessary
  // because we need to notify all views in the hierarchy that they did enter reuse pool.
  XCTAssertTrue(isDidEnterReusePoolIsCalledOnDescendant(container));
}

static void checkSubviewsAreHidden(UIView *view, BOOL isHidden, NSInteger *numberOfViewsMatched)
{
  for (UIView *subview in view.subviews) {
    if (subview.isHidden == isHidden) {
      (*numberOfViewsMatched)++;
    }
    checkSubviewsAreHidden(subview, isHidden, numberOfViewsMatched);
  }
}

static BOOL isDidEnterReusePoolIsCalledOnDescendant(UIView *view)
{
  for (UIView *subview in view.subviews) {
    const auto reusableView = CK::objCForceCast<CKTestReusableView>(subview);
    if (!reusableView.isDidEnterReusePoolCalled) {
      return NO;
    }
  }
  return YES;
}

@end

@implementation CKAddSubviewOnlyView

- (void)addSubview:(UIView *)view
{
  _numberOfSubviewsAdded++;
  [super addSubview:view];
}

- (void)exchangeSubviewAtIndex:(NSInteger)index1 withSubviewAtIndex:(NSInteger)index2
{
  [NSException raise:NSGenericException format:@"Unexpected %@", NSStringFromSelector(_cmd)];
}

- (void)bringSubviewToFront:(UIView *)view
{
  [NSException raise:NSGenericException format:@"Unexpected %@", NSStringFromSelector(_cmd)];
}

- (void)sendSubviewToBack:(UIView *)view
{
  [NSException raise:NSGenericException format:@"Unexpected %@", NSStringFromSelector(_cmd)];
}

- (void)insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview
{
  [NSException raise:NSGenericException format:@"Unexpected %@", NSStringFromSelector(_cmd)];
}

- (void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview
{
  [NSException raise:NSGenericException format:@"Unexpected %@", NSStringFromSelector(_cmd)];
}

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index
{
  [NSException raise:NSGenericException format:@"Unexpected %@", NSStringFromSelector(_cmd)];
}

@end

@implementation CKTestReusableView

- (void)didEnterReusePool
{
  _isDidEnterReusePoolCalled = YES;
}

@end
