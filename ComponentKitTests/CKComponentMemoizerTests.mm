#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentMemoizer.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKMemoizingComponent.h>

#import <ComponentKit/CKFlexboxComponent.h>

static NSInteger componentMemoizerTestsNumComponentCreation = 0;

typedef CKComponent *(^kCKMemoizationChildCreationBlock)();

@interface CKComponentMemoizerTests : XCTestCase

@end

@interface CKTestMemoizedComponentState : NSObject
@property (atomic, readwrite, assign) NSInteger computeCount;
@end

@implementation CKTestMemoizedComponentState
@end

@interface CKTestMemoizedComponent : CKCompositeComponent

+ (instancetype)newWithString:(NSString *)string
                       number:(NSInteger)number;

+ (instancetype)newWithString:(NSString *)string
                       number:(NSInteger)number
                   childBlock:(kCKMemoizationChildCreationBlock)childBlock;

@property (nonatomic, copy) NSString *string;
@property (nonatomic, assign) NSInteger number;

@property (nonatomic, strong) CKTestMemoizedComponentState *state;

@end

@implementation CKTestMemoizedComponent

+ (instancetype)newWithString:(NSString *)string
                       number:(NSInteger)number
{
  return [self newWithString:string
                      number:number
                  childBlock:^{
                    return [CKComponent newWithView:{} size:{}];
                  }];
}

+ (instancetype)newWithString:(NSString *)string
                       number:(NSInteger)number
                   childBlock:(kCKMemoizationChildCreationBlock)childBlock
{
  auto key = CKMakeTupleMemoizationKey(string, number);
  return
  CKMemoize(key, ^{
    CKComponentScope scope(self);

    CKTestMemoizedComponent *c =
    [super
     newWithView:{{[UIView class]}}
     component:childBlock()];

    if (c) {
      c->_string = [string copy];
      c->_number = number;
      c->_state = scope.state();
      componentMemoizerTestsNumComponentCreation += 1;
    }

    return c;
  });
}

+ (id)initialState
{
  return [CKTestMemoizedComponentState new];
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize restrictedToSize:(const CKComponentSize &)size relativeToParentSize:(CGSize)parentSize
{
  CKComponentLayout l = CKMemoizeLayout(self, constrainedSize, size, parentSize, ^CKComponentLayout{
    _state.computeCount = _state.computeCount + 1;
    return [super computeLayoutThatFits:constrainedSize
                       restrictedToSize:size
                   relativeToParentSize:parentSize];
  });
  return l;
}

@end

@interface TestStateListener: NSObject<CKComponentStateListener>
@end

@implementation TestStateListener {
  @package
  CKComponentStateUpdateMap _pendingStateUpdates;
}

- (void)componentScopeHandle:(CKComponentScopeHandle *)handle
              rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
       didReceiveStateUpdate:(id (^)(id))stateUpdate
                    metadata:(const CKStateUpdateMetadata)metadata
                        mode:(CKUpdateMode)mode
{
  _pendingStateUpdates[handle].push_back(stateUpdate);
}
@end

@implementation CKComponentMemoizerTests

- (void)testThatMemoizableComponentsAreMemoized
{
  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  auto build = ^{
    return [CKTestMemoizedComponent newWithString:@"ABCD" number:123];
  };

  CKComponentMemoizerState *memoizerState;
  CKBuildComponentResult result;
  {
    // Vend components from the current layout to be available in the new state and layout calculations
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(nil);
    result = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }

  CKBuildComponentResult result2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
  }

  XCTAssertEqualObjects(result.component, result2.component, @"Should return the original component the second time");
}

- (void)testThatMemoizableComponentsAreMemoizedEvenWithLayoutCalled
{
  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  auto build = ^{
    return [CKTestMemoizedComponent newWithString:@"ABCD" number:123];
  };

  CKComponentMemoizerState *memoizerState;
  CKBuildComponentResult result;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(nil);
    result = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }

  {
    // Do layout now
    CKComponentMemoizer<CKComponentLayoutMemoizerState> memoizer(nil);
    [result.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];
  }

  CKBuildComponentResult result2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
  }

  XCTAssertEqualObjects(result.component, result2.component, @"Should return the original component the second time");
}

- (void)testThatMemoizableComponentsAreMemoizedWithMemoizingComponentAsParent
{
  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  __block CKComponent *lastCreatedComponent = nil;

  auto build = ^{
    return [CKMemoizingComponent
            newWithComponentBlock:^{
              CKComponent *newResult = [CKTestMemoizedComponent newWithString:@"ABCD" number:123];
              if (lastCreatedComponent != nil) {
                XCTAssertEqualObjects(lastCreatedComponent, newResult, @"Components should be identical on the second run.");
              }
              lastCreatedComponent = newResult;
              return newResult;
            }];
  };
  CKBuildComponentResult result = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
  CKBuildComponent(result.scopeRoot, pendingStateUpdates, build);
}

- (void)testThatWhenMultipleComponentsAreMutuallyMemoizableTheyAreStillDistict
{
  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  auto build = ^{
    return [CKFlexboxComponent
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
  CKComponentMemoizerState *componentMemoizerState;
  CKComponentLayoutMemoizerState *layoutMemoizerState;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(nil);
    CKComponentMemoizer<CKComponentLayoutMemoizerState> layoutMemoizer(nil);

    result1 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    layout1 = [result1.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];
    componentMemoizerState = memoizer.nextMemoizerState();
    layoutMemoizerState = layoutMemoizer.nextMemoizerState();
  }

  // Vend components from the current layout to be available in the new state and layout calculations
  CKBuildComponentResult result2;
  CKComponentLayout layout2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(componentMemoizerState);
    CKComponentMemoizer<CKComponentLayoutMemoizerState> layoutMemoizer(layoutMemoizerState);

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
  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  auto build = ^{
    return [CKTestMemoizedComponent newWithString:@"ABCD" number:123];
  };

  CKComponentMemoizerState *componentMemoizerState;
  CKComponentLayoutMemoizerState *layoutMemoizerState;
  CKBuildComponentResult result1;
  {
    // Vend components from the current layout to be available in the new state and layout calculations
    CKComponentMemoizer<CKComponentMemoizerState> componentMemoizer(nil);
    CKComponentMemoizer<CKComponentLayoutMemoizerState> layoutMemoizer(nil);
    result1 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    CKComponentLayout layout = [result1.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];

    componentMemoizerState = componentMemoizer.nextMemoizerState();
    layoutMemoizerState = layoutMemoizer.nextMemoizerState();
  }

  CKBuildComponentResult result2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(componentMemoizerState);
    CKComponentMemoizer<CKComponentLayoutMemoizerState> layoutMemoizer(layoutMemoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    CKComponentLayout layout = [result2.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];
  }

  XCTAssertEqualObjects(result1.component, result2.component, @"Should return the original component the second time");

  CKTestMemoizedComponent *testComponent = (CKTestMemoizedComponent *)result1.component;

  XCTAssertEqual(testComponent.state.computeCount, 1, @"Should only compute once");
}

- (void)testComputeLayoutCalledTwiceWhenNotEqualInputs
{
  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  auto build = ^{
    return [CKTestMemoizedComponent newWithString:@"ABCD" number:123];
  };

  CKComponentMemoizerState *componentMemoizerState;
  CKComponentLayoutMemoizerState *layoutMemoizerState;
  CKBuildComponentResult result1;
  {
    // Vend components from the current layout to be available in the new state and layout calculations
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(nil);
    CKComponentMemoizer<CKComponentLayoutMemoizerState> layoutMemoizer(nil);
    result1 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    CKComponentLayout layout = [result1.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];

    componentMemoizerState = memoizer.nextMemoizerState();
    layoutMemoizerState = layoutMemoizer.nextMemoizerState();
  }

  CKBuildComponentResult result2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(componentMemoizerState);
    CKComponentMemoizer<CKComponentLayoutMemoizerState> layoutMemoizer(layoutMemoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    CKComponentLayout layout = [result2.component layoutThatFits:{CGSizeMake(100, 100), CGSizeMake(100, 100)}
                                                      parentSize:CGSizeMake(100, 100)];
  }

  XCTAssertEqualObjects(result1.component, result2.component, @"Should return the original component the second time");

  CKTestMemoizedComponent *testComponent = (CKTestMemoizedComponent *)result1.component;

  XCTAssertEqual(testComponent.state.computeCount, 2, @"Should compute layout again if constraints change");
}

- (void)testComputeLayoutOnlyCalledOnceWhenEqualInputsAndWeSplitCreationAndLayout
{
  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  auto build = ^{
    return [CKTestMemoizedComponent newWithString:@"ABCD" number:123];
  };

  CKComponentMemoizerState *memoizerState;
  CKBuildComponentResult result1;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(nil);
    result1 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }

  CKComponentLayoutMemoizerState *layoutMemoizerState;
  {
    CKComponentMemoizer<CKComponentLayoutMemoizerState> memoizer(nil);
    CKComponentLayout layout = [result1.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];
    layoutMemoizerState = memoizer.nextMemoizerState();
  }

  CKBuildComponentResult result2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }

  {
    CKComponentMemoizer<CKComponentLayoutMemoizerState> memoizer(layoutMemoizerState);
    CKComponentLayout layout = [result2.component layoutThatFits:{CGSizeZero, CGSizeZero} parentSize:CGSizeZero];
    layoutMemoizerState = memoizer.nextMemoizerState();
  }

  XCTAssertEqualObjects(result1.component, result2.component, @"Should return the original component the second time");

  CKTestMemoizedComponent *testComponent = (CKTestMemoizedComponent *)result1.component;

  XCTAssertEqual(testComponent.state.computeCount, 1, @"Should only compute once");
}

- (void)testComponentMemoizationKeysCompareObjCObjectsWithIsEqual
{
  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  // Make two objects here that are mutable copies
  auto build = ^{
    return [CKTestMemoizedComponent newWithString:[@"ABCD" mutableCopy] number:123];
  };

  CKComponentMemoizerState *memoizerState;
  CKBuildComponentResult result;
  CKComponentLayout layout;
  {
    // Vend components from the current layout to be available in the new state and layout calculations
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(nil);
    result = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }

  CKBuildComponentResult result2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
  }

  XCTAssertEqualObjects(result.component, result2.component, @"Should return the original component the second time");
}

- (void)DISABLEDtestComponentMemoizationCachesChildComponents
{
  componentMemoizerTestsNumComponentCreation = 0;

  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  __block NSInteger number = 0;
  auto build = ^{
    return [CKTestMemoizedComponent
            newWithString:[@"ROOT" mutableCopy]
            number:number
            childBlock:^{
              return [CKFlexboxComponent
                      newWithView:{}
                      size:{}
                      style:{}
                      children:{
                        {[CKTestMemoizedComponent newWithString:@"A" number:2]},
                        {[CKTestMemoizedComponent newWithString:@"B" number:3]},
                        {[CKTestMemoizedComponent newWithString:@"C" number:4]},
                      }];
            }];
  };

  CKComponentMemoizerState *memoizerState;
  CKBuildComponentResult result;
  CKComponentLayout layout;
  {
    // Vend components from the current layout to be available in the new state and layout calculations
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(nil);
    result = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }
  CKBuildComponentResult result2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }

  XCTAssert(componentMemoizerTestsNumComponentCreation == 4, @"Should have initialized only four times");
  XCTAssertEqualObjects(result.component, result2.component, @"Should return the original component the second time");

  // This is a block var so it will invalidate the root's caching
  number = 1;
  CKBuildComponentResult result3;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result3 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }

  XCTAssert(componentMemoizerTestsNumComponentCreation == 5, @"Should have initialized only one additional time");
  XCTAssertNotEqual(result3.component, result2.component, @"Should return the different component the third time");
}

- (void)testComponentMemoizationDoesNotLeak
{
  componentMemoizerTestsNumComponentCreation = 0;

  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  __block NSInteger number = 0;
  auto build = ^{
    kCKMemoizationChildCreationBlock childBlock;
    if (number % 2 == 0) {
      childBlock = ^{
        return [CKFlexboxComponent
                newWithView:{}
                size:{}
                style:{}
                children:{
                  {[CKTestMemoizedComponent newWithString:@"A" number:2]},
                  {[CKTestMemoizedComponent newWithString:@"B" number:3]},
                  {[CKTestMemoizedComponent newWithString:@"C" number:4]},
                }];
      };
    } else {
      childBlock = ^{
        return [CKFlexboxComponent
                newWithView:{}
                size:{}
                style:{}
                children:{
                  {[CKTestMemoizedComponent newWithString:@"A" number:2]},
                  {[CKTestMemoizedComponent newWithString:@"B" number:3]},
                }];
      };
    }
    return [CKTestMemoizedComponent
            newWithString:[@"ROOT" mutableCopy]
            number:number
            childBlock:childBlock];
  };

  CKComponentMemoizerState *memoizerState;
  CKBuildComponentResult result;
  CKComponentLayout layout;
  {
    // Vend components from the current layout to be available in the new state and layout calculations
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(nil);
    result = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }
  XCTAssert(componentMemoizerTestsNumComponentCreation == 4, @"Should have initialized only four times");

  // This is a block var so it will invalidate the root's caching
  // After this block we should no longer have "C" cached
  number = 1;
  CKBuildComponentResult result2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }
  XCTAssert(componentMemoizerTestsNumComponentCreation == 5, @"Should have initialized only five times");

  number = 2;
  CKBuildComponentResult result3;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result3 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }
  XCTAssert(componentMemoizerTestsNumComponentCreation == 7, @"Should have initialized seven times, again for root and C");
}

- (void)DISABLEDtestComponentMemoizationHitsDontBreakChildMemoization
{
  componentMemoizerTestsNumComponentCreation = 0;

  CKComponentScopeRoot *scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentStateUpdateMap pendingStateUpdates;

  __block NSInteger number = 0;
  auto build = ^{
    return [CKTestMemoizedComponent
            newWithString:[@"ROOT" mutableCopy]
            number:number
            childBlock:^{
              return [CKFlexboxComponent
                      newWithView:{}
                      size:{}
                      style:{}
                      children:{
                        {[CKTestMemoizedComponent newWithString:@"A" number:2]},
                        {[CKTestMemoizedComponent newWithString:@"B" number:3]},
                        {[CKTestMemoizedComponent newWithString:@"C" number:4]},
                      }];
            }];
  };

  CKComponentMemoizerState *memoizerState;
  CKBuildComponentResult result;
  CKComponentLayout layout;
  {
    // Vend components from the current layout to be available in the new state and layout calculations
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(nil);
    result = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }
  XCTAssert(componentMemoizerTestsNumComponentCreation == 4, @"Should have initialized only four times");

  // Nothing has changed so we're all dandy, we should still have all four cached
  CKBuildComponentResult result2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }
  XCTAssert(componentMemoizerTestsNumComponentCreation == 4, @"Should have initialized only four times");
  XCTAssertEqual(result.component, result2.component, @"Components should be equal");

  number = 1;
  CKBuildComponentResult result3;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result3 = CKBuildComponent(scopeRoot, pendingStateUpdates, build);
    memoizerState = memoizer.nextMemoizerState();
  }
  XCTAssertNotEqual(result.component, result3.component, @"Components should not be equal");
  XCTAssert(componentMemoizerTestsNumComponentCreation == 5, @"Have only invalidated the root");
}

- (void)disabled_testWhenComponentHasPendingStateUpdateItIsRebuiltFromScratch
{
  const auto listener = [TestStateListener new];
  const auto scopeRoot = CKComponentScopeRootWithDefaultPredicates(listener);
  const auto build = ^{ return [CKTestMemoizedComponent newWithString:@"ABCD" number:123]; };
  CKComponentMemoizerState *memoizerState;
  CKBuildComponentResult result;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(nil);
    result = CKBuildComponent(scopeRoot, {}, build);
    memoizerState = memoizer.nextMemoizerState();
  }

  const auto anyStateUpdate = ^(id oldState){ return oldState; };
  [result.component updateState:anyStateUpdate mode:CKUpdateModeAsynchronous];
  CKBuildComponentResult result2;
  {
    CKComponentMemoizer<CKComponentMemoizerState> memoizer(memoizerState);
    result2 = CKBuildComponent(scopeRoot, listener->_pendingStateUpdates, build);
  }

  XCTAssertNotEqualObjects(result.component, result2.component, @"Should return a different component the second time");
}

@end
