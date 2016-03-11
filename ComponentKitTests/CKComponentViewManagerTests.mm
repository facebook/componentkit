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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>

using CK::Component::ViewManager;

@interface CKComponentViewManagerTests : XCTestCase
@end

/** Overrides all subview related methods *except* addSubview: to throw. */
@interface CKAddSubviewOnlyView : UIView
@property (nonatomic, assign) NSUInteger numberOfSubviewsAdded;
@end

@implementation CKComponentViewManagerTests

- (void)testThatComponentViewManagerVendsRecycledView
{
  CKComponent *component = [CKComponent newWithView:{[UIView class], {}} size:{}];

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
  CKComponent *component = [CKComponent newWithView:{[UIView class], {}} size:{}];

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
  CKComponent *imageView = [CKComponent newWithView:{[UIImageView class], {}} size:{}];
  CKComponent *button = [CKComponent newWithView:{[UIButton class], {}} size:{}];
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
  CKComponent *imageView = [CKComponent newWithView:{[UIImageView class], {}} size:{}];
  CKComponent *button = [CKComponent newWithView:{[UIButton class], {}} size:{}];

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
  [CKComponent newWithView:{[UIView class], {
    {{@selector(setBackgroundColor:), [UIColor blueColor]}}
  }} size:{}];

  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *subview;

  {
    ViewManager m(container);
    subview = m.viewForConfiguration([bgColorComponent class], [bgColorComponent viewConfiguration]);
  }

  CKComponent *alphaComponent =
  [CKComponent newWithView:{[UIView class], {
    {{@selector(setAlpha:), @0.5}}
  }} size:{}];

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
  CKComponent *testComponent = [CKComponent newWithView:{std::move(customClass), {}} size:{}];
  UIView *container = [[UIView alloc] init];
  CK::Component::ViewReuseUtilities::mountingInRootView(container);
  ViewManager m(container);
  UIView *subview = m.viewForConfiguration([testComponent class], [testComponent viewConfiguration]);
  XCTAssertTrue([subview isKindOfClass:[UIImageView class]], @"Expected +newView to vend a UIImageView");
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
