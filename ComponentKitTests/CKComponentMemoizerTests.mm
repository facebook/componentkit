#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "CKComponent.h"
#import "CKComponentMemoizer.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKComponentInternal.h"
#import "CKInternalHelpers.h"
#import "CKMacros.h"

#import "CKStackLayoutComponent.h"

@interface CKComponentMemoizerTests : XCTestCase

@end

@interface CKTestMemoizedComponent : CKComponent

@property (nonatomic, copy) NSString *string;
@property (nonatomic, assign) NSInteger number;

@property (nonatomic, assign, readonly) NSInteger computeCount;

@end

@implementation CKTestMemoizedComponent

+ (instancetype)newWithString:(NSString *)string number:(NSInteger)number
{
  auto key = CKMakeTupleMemoizationKey(string, number);
  return
  CKMemoize(key, ^{
    CKTestMemoizedComponent *c =
    [self
     newWithView:{{[UIView class]}}
     size:{}];

    c->_string = [string copy];
    c->_number = number;

    return c;
  });
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize restrictedToSize:(const CKComponentSize &)size relativeToParentSize:(CGSize)parentSize
{
  CKComponentLayout l = [super computeLayoutThatFits:constrainedSize restrictedToSize:size relativeToParentSize:parentSize];
  _computeCount++;
  return l;
}

- (BOOL)shouldMemoizeLayout
{
  return YES;
}

@end

@implementation CKComponentMemoizerTests {
}

- (void)testThatMemoizableComponentsAreMemoized
{
  CKComponentScopeRoot *scopeRoot = [CKComponentScopeRoot rootWithListener:nil];
  CKComponentStateUpdateMap pendingStateUpdates;

  auto build = ^{
    return [CKTestMemoizedComponent newWithString:@"ABCD" number:123];
  };

  id memoizerState;
  CKBuildComponentResult result;
  CKComponentLayout layout;
  {
    // Vend components from the current layout to be available in the new state and layout calculations
    CKComponentMemoizer memoizer(nil);
    result = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }

  CKBuildComponentResult result2;
  {
    CKComponentMemoizer memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
  }

  XCTAssertEqualObjects(result.component, result2.component, @"Should return the original component the second time");
}

- (void)testThatWhenMultipleComponentsAreMutuallyMemoizableTheyAreStillDistict
{
  CKComponentScopeRoot *scopeRoot = [CKComponentScopeRoot rootWithListener:nil];
  CKComponentStateUpdateMap pendingStateUpdates;

  auto build = ^{
    return [CKStackLayoutComponent
            newWithView:{}
            size:{}
            style:{}
            children:{
              {[CKTestMemoizedComponent newWithString:@"ABCD" number:123]},
              {[CKTestMemoizedComponent newWithString:@"D" number:0]},
              {[CKTestMemoizedComponent newWithString:@"ABCD" number:123]},
            }];
  };

  
  CKBuildComponentResult result1;
  CKComponentLayout layout1;
  id memoizerState;
  {
    CKComponentMemoizer memoizer(nil);
    
    result1 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    layout1 = [result1.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];
    memoizerState = memoizer.nextMemoizerState();
  }

  // Vend components from the current layout to be available in the new state and layout calculations
  CKBuildComponentResult result2;
  CKComponentLayout layout2;
  {
    CKComponentMemoizer memoize(memoizerState);

    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    layout2 = [result2.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];
  }

  std::function<NSSet *(const CKComponentLayout &, NSString *)> findAllMatching =
  [&findAllMatching](const CKComponentLayout &layout, NSString *string){
    NSMutableSet *result = [NSMutableSet set];
    if (layout.component && [layout.component isKindOfClass:[CKTestMemoizedComponent class]]) {
      CKTestMemoizedComponent *tc = (CKTestMemoizedComponent *)layout.component;
      if ([tc.string isEqualToString:string]) {
        [result addObject:layout.component];
      }
    }
    for (auto sublayout : *layout.children) {
      [result unionSet:findAllMatching(sublayout.layout, string)];
    }
    return result;
  };

  NSSet *components1 = findAllMatching(layout1, @"ABCD");
  NSSet *components2 = findAllMatching(layout2, @"ABCD");

  XCTAssertEqual(components1.count, 2, @"Should have created 2 distinct ABCD components.");
  XCTAssertEqual(components2.count, 2, @"Should have created 2 distinct ABCD components.");
  XCTAssertEqualObjects(components1, components2, @"Should have reused both distinct components for <ACBD, 123>.");
}

- (void)testComputeLayoutOnlyCalledOnceWhenEqualInputs
{
  CKComponentScopeRoot *scopeRoot = [CKComponentScopeRoot rootWithListener:nil];
  CKComponentStateUpdateMap pendingStateUpdates;

  auto build = ^{
    return [CKTestMemoizedComponent newWithString:@"ABCD" number:123];
  };

  id memoizerState;
  CKBuildComponentResult result1;
  CKComponentLayout layout;
  {
    // Vend components from the current layout to be available in the new state and layout calculations
    CKComponentMemoizer memoizer(nil);
    result1 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    CKComponentLayout layout = [result1.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];

    memoizerState = memoizer.nextMemoizerState();
  }

  CKBuildComponentResult result2;
  {
    CKComponentMemoizer memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    CKComponentLayout layout = [result2.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];
  }

  XCTAssertEqualObjects(result1.component, result2.component, @"Should return the original component the second time");

  CKTestMemoizedComponent *testComponent = (CKTestMemoizedComponent *)result1.component;

  XCTAssertEqual(testComponent.computeCount, 1, @"Should only compute once");
}

- (void)testComponentMemoizationKeysCompareObjCObjectsWithIsEqual
{
  CKComponentScopeRoot *scopeRoot = [CKComponentScopeRoot rootWithListener:nil];
  CKComponentStateUpdateMap pendingStateUpdates;

  // Make two objects here that are mutable copies
  auto build = ^{
    return [CKTestMemoizedComponent newWithString:[@"ABCD" mutableCopy] number:123];
  };

  id memoizerState;
  CKBuildComponentResult result;
  CKComponentLayout layout;
  {
    // Vend components from the current layout to be available in the new state and layout calculations
    CKComponentMemoizer memoizer(nil);
    result = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }

  CKBuildComponentResult result2;
  {
    CKComponentMemoizer memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
  }

  XCTAssertEqualObjects(result.component, result2.component, @"Should return the original component the second time");
}

@end
