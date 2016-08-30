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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentConstantDecider.h>
#import <ComponentKit/CKComponentDataSource.h>
#import <ComponentKit/CKComponentDataSourceOutputItem.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/ComponentUtilities.h>

#import "CKTestRunLoopRunning.h"
#import "CKComponentDataSourceTestDelegate.h"
#import "CKComponentLifecycleManagerAsynchronousUpdateHandler.h"

using namespace CK::ArrayController;

namespace CK {

  namespace ComponentDataSource {

    struct Item {
      id<NSObject> object;

      Item(id<NSObject> o) : object(o) {};

      Item() : object(nil) {};

      bool operator==(const Item &other) const {
        return CKObjectIsEqual(object, other.object);
      }
    };

    typedef std::vector<Item> Items;

    struct Section {
      Items items;

      Section(Items it) : items(it) {};

      Section() : items({}) {};

      bool operator==(const Section &other) const {
        return items == other.items;
      }
    };

    typedef std::vector<Section> State;

    // Returns the state of all the empty and non-empty sections in the data source.
    // Useful to compare expected state with actual state in tests. Expected state can be declared inline in the test.
    static State state(CKComponentDataSource *dataSource) {
      __block State state;
      const NSInteger numberOfSections = [dataSource numberOfSections];
      for (NSInteger section = 0 ; section < numberOfSections ; ++section) {
        if ([dataSource numberOfObjectsInSection:section] > 0) {
          __block Items items;
          [dataSource enumerateObjectsInSectionAtIndex:section
                                            usingBlock:^(CKComponentDataSourceOutputItem *outputItem, NSIndexPath *indexPath, BOOL *stop) {
                                              items.push_back({[outputItem model]});
                                            }];
          state.push_back({items});
        } else {
          state.push_back({});
        }
      }
      return state;
    }

  }

}

#pragma mark -

@interface CKComponentDataSourceTests : XCTestCase <CKComponentProvider>
@end

/**
 Basic tests for state, initialization, etc.
 */
@implementation CKComponentDataSourceTests
{
  CKComponentDataSource *_dataSource;
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return nil;
}

- (void)setUp
{
  [super setUp];
  CKComponentDataSource *dataSource = [[CKComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:[CKComponentConstantDenyingDecider class]];
  _dataSource = dataSource;
}

- (void)tearDown
{
  _dataSource = nil;
  [super tearDown];
}

- (void)testInitialState
{
  CKComponentDataSource *dataSource = [[CKComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:[CKComponentConstantDenyingDecider class]];
  XCTAssertNotNil(dataSource);
  XCTAssertEqual([dataSource numberOfSections], 0);
  XCTAssertThrowsSpecificNamed([dataSource objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]],
                               NSException,
                               NSRangeException);
  XCTAssertFalse([dataSource isComputingChanges]);
}

@end

static const CKSizeRange constrainedSize = {{320, 0}, {320, INFINITY}};

#pragma mark -

@interface CKComponentDataSourceSectionTests : XCTestCase
@end

@implementation CKComponentDataSourceSectionTests
{
  CKComponentDataSource *_dataSource;
  CKComponentDataSourceTestDelegate *_delegate;
}

- (void)setUp
{
  [super setUp];

  CKComponentDataSourceTestDelegate *delegate = [[CKComponentDataSourceTestDelegate alloc] init];

  CKComponentDataSource *dataSource = [[CKComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:[CKComponentConstantDenyingDecider class]];

  dataSource.delegate = delegate;

  _dataSource = dataSource;
  _delegate = delegate;
}

- (void)tearDown
{
  _dataSource = nil;
  _delegate = nil;
  [super tearDown];
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
{
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    if (_delegate.changeCount > changeCount) {
      XCTFail(@"%lu", (unsigned long)_delegate.changeCount);
    }
    return (_delegate.changeCount == changeCount);
  }), @"timeout");
}

- (void)configureWithSingleEmptySection
{
  Sections sections;
  sections.insert(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)configureWithSingleSectionWithSingleItem
{
  Sections sections;
  sections.insert(0);
  Input::Items items;
  items.insert({0, 0}, @"Hello");

  [_dataSource enqueueChangeset:{sections, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testInsertionOfSingleSection
{
  Sections sections;
  sections.insert(0);

  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {}
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testAppendOfMultipleSections
{
  [self configureWithSingleSectionWithSingleItem];

  Sections sections;
  sections.insert(1);
  sections.insert(2);
  sections.insert(3);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"}
      }
    },
    {},
    {},
    {}
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testPrependOfMultipleSections
{
  [self configureWithSingleSectionWithSingleItem];

  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {},
    {},
    {},
    {
      {
        {@"Hello"}
      }
    }
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testPrependAndAppendMultipleSections
{
  [self configureWithSingleSectionWithSingleItem];

  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(3);
  sections.insert(4);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {},
    {},
    {
      {
        {@"Hello"}
      }
    },
    {},
    {}
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testEmptyDataSourceThrowsOnRemovalOfSection
{
  Sections sections;
  sections.remove(0);
  Input::Changeset changeset = {sections, {}};
  XCTAssertThrowsSpecificNamed([_dataSource enqueueChangeset:changeset constrainedSize:constrainedSize],
                               NSException,
                               NSInternalInconsistencyException);
}

- (void)testRemovalOfSingleEmptySectionLeavesDataSourceEmpty
{
  [self configureWithSingleEmptySection];

  Sections sections;
  sections.remove(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {};

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)configureWithMultipleEmptySections
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testRemovalOfMultipleEmptySectionsFromHead
{
  [self configureWithMultipleEmptySections];

  Sections sections;
  sections.remove(0);
  sections.remove(1);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {}
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testRemovalOfMultipleEmptySectionsFromTail
{
  [self configureWithMultipleEmptySections];

  Sections sections;
  sections.remove(1);
  sections.remove(2);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {}
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testRemovalOfEmptySectionsFromHeadAndTail
{
  [self configureWithMultipleEmptySections];

  Sections sections;
  sections.remove(0);
  sections.remove(2);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {}
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

@end

#pragma mark -

@interface CKComponentDataSourceItemTests : XCTestCase
@end

@implementation CKComponentDataSourceItemTests
{
  CKComponentDataSource *_dataSource;
  CKComponentDataSourceTestDelegate *_delegate;
}

- (void)setUp
{
  [super setUp];

  CKComponentDataSourceTestDelegate *delegate = [[CKComponentDataSourceTestDelegate alloc] init];

  CKComponentDataSource *dataSource = [[CKComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:[CKComponentConstantDenyingDecider class]];

  dataSource.delegate = delegate;

  _dataSource = dataSource;
  _delegate = delegate;
}

- (void)tearDown
{
  _dataSource = nil;
  _delegate = nil;
  [super tearDown];
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
{
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    if (_delegate.changeCount > changeCount) {
      XCTFail(@"%lu", (unsigned long)_delegate.changeCount);
    }
    return (_delegate.changeCount == changeCount);
  }), @"timeout");
}

- (void)configureWithSingleEmptySection
{
  Sections sections;
  sections.insert(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testInsertion
{
  [self configureWithSingleEmptySection];

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"}
      }
    }
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testEmptySectionThrowsOnRemovalOfItem
{
  [self configureWithSingleEmptySection];

  Input::Items items;
  items.remove({0, 0});
  Input::Changeset changeset = {{}, items};
  XCTAssertThrowsSpecificNamed([_dataSource enqueueChangeset:changeset constrainedSize:constrainedSize],
                               NSException,
                               NSInternalInconsistencyException);
}

- (void)testRemovalOfLastItemLeavesSectionEmpty
{
  [self configureWithSingleItemInSingleSection];

  Input::Items items;
  items.remove({0, 0});
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {}
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testInsertionOfMultipleItemsInEmptySection
{
  [self configureWithSingleEmptySection];

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({0, 1}, @"World");
  items.insert({0, 2}, @"Batman");
  items.insert({0, 3}, @"Robin");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
        {@"World"},
        {@"Batman"},
        {@"Robin"}
      }
    }
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)configureWithSingleItemInSingleSection
{
  [self configureWithSingleEmptySection];
  Input::Items items;
  items.insert({0, 0}, @"Hello");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testPrependOfMultipleItemsInNonEmptySection
{
  [self configureWithSingleItemInSingleSection];

  Input::Items items;
  items.insert({0, 0}, @"World");
  items.insert({0, 1}, @"Batman");
  items.insert({0, 2}, @"Robin");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"World"},
        {@"Batman"},
        {@"Robin"},
        {@"Hello"},
      }
    }
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testAppendOfMultipleItemsInNonEmptySection
{
  [self configureWithSingleItemInSingleSection];

  Input::Items items;
  items.insert({0, 1}, @"World");
  items.insert({0, 2}, @"Batman");
  items.insert({0, 3}, @"Robin");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
        {@"World"},
        {@"Batman"},
        {@"Robin"},
      }
    }
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testPrependAndAppendOfMultipleItemsInNonEmptySection
{
  [self configureWithSingleItemInSingleSection];

  Input::Items items;
  items.insert({0, 0}, @"World");
  items.insert({0, 2}, @"Batman");
  items.insert({0, 3}, @"Robin");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"World"},
        {@"Hello"},
        {@"Batman"},
        {@"Robin"},
      }
    }
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)configureWithMultipleItemsInSingleSection
{
  [self configureWithSingleEmptySection];

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({0, 1}, @"World");
  items.insert({0, 2}, @"Batman");
  items.insert({0, 3}, @"Robin");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testRemovalAtHeadOfNonEmptySection
{
  [self configureWithMultipleItemsInSingleSection];

  Input::Items items;
  items.remove({0, 0});
  items.remove({0, 1});
  items.remove({0, 2});
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"Robin"},
      }
    }
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testRemovalAtTailOfNonEmptySection
{
  [self configureWithMultipleItemsInSingleSection];

  Input::Items items;
  items.remove({0, 1});
  items.remove({0, 2});
  items.remove({0, 3});
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
      }
    }
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testRemovalAtHeadAndTailOfNonEmptySection
{
  [self configureWithMultipleItemsInSingleSection];

  Input::Items items;
  items.remove({0, 0});
  items.remove({0, 2});
  items.remove({0, 3});
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"World"},
      }
    }
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testInsertionOfItemsInMultipleSections
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({0, 1}, @"World");
  items.insert({1, 0}, @"Batman");
  items.insert({1, 1}, @"Robin");

  [_dataSource enqueueChangeset:{sections, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
        {@"World"},
      }
    },
    {
      {
        {@"Batman"},
        {@"Robin"},
      }
    },
    {},
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)configureWithMultipleSectionsAndItems
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({0, 1}, @"World");
  items.insert({1, 0}, @"Batman");
  items.insert({1, 1}, @"Robin");

  [_dataSource enqueueChangeset:{sections, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testRemovalOfItemsInMultipleSections
{
  [self configureWithMultipleSectionsAndItems];

  Input::Items items;
  items.remove({0, 0});
  items.remove({1, 0});

  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"World"},
      }
    },
    {
      {
        {@"Robin"},
      }
    },
    {},
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testUpdateOfMultipleItems
{
  [self configureWithMultipleSectionsAndItems];

  Input::Items items;
  items.update({0, 1}, @"Universe");
  items.update({1, 0}, @"Joker");
  items.update({1, 1}, @"Harley");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
        {@"Universe"},
      }
    },
    {
      {
        {@"Joker"},
        {@"Harley"},
      }
    },
    {},
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testUpdateOfItemInEmptySectionThrows
{
  [self configureWithSingleEmptySection];
  Input::Items items;
  items.update({0, 0}, @"nonsense");
  Input::Changeset changeset = {{}, items};
  XCTAssertThrowsSpecificNamed([_dataSource enqueueChangeset:changeset constrainedSize:constrainedSize],
                               NSException,
                               NSRangeException);
}

- (void)testEnqueueReload
{
  [self configureWithSingleItemInSingleSection];
  [_dataSource enqueueReload];

  [self waitUntilChangeCountIs:1];

  CK::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
      }
    },
  };

  CK::ComponentDataSource::State state = CK::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

@end

#pragma mark -

@interface CKComponentDataSourceInflightChangesTests : XCTestCase
@end

@implementation CKComponentDataSourceInflightChangesTests
{
  CKComponentDataSource *_dataSource;
  CKComponentDataSourceTestDelegate *_delegate;
}

- (void)setUp
{
  [super setUp];

  CKComponentDataSourceTestDelegate *delegate = [[CKComponentDataSourceTestDelegate alloc] init];

  CKComponentDataSource *dataSource = [[CKComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:[CKComponentConstantDenyingDecider class]];

  dataSource.delegate = delegate;

  _dataSource = dataSource;
  _delegate = delegate;
}

- (void)tearDown
{
  _dataSource = nil;
  _delegate = nil;
  [super tearDown];
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
{
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    if (_delegate.changeCount > changeCount) {
      XCTFail(@"%lu", (unsigned long)_delegate.changeCount);
    }
    return _delegate.changeCount == changeCount;
  }), @"timeout");
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
                      onChange:(void(^)(NSUInteger changeCount, CK::ComponentDataSource::State state))onChange
{
  id dataSource = _dataSource; // Stop ARC complaining about a retain-cycle.
  _delegate.onChange = ^(NSUInteger count) {
    onChange(count, CK::ComponentDataSource::state(dataSource));
  };
  [self waitUntilChangeCountIs:changeCount];
}

- (void)configureWithSingleEmptySection
{
  Sections sections;
  sections.insert(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testInsertionOfSectionsInSeparateChangesets
{
  Sections sections1;
  sections1.insert(0);
  sections1.insert(1);
  [_dataSource enqueueChangeset:{sections1, {}} constrainedSize:constrainedSize];

  Sections sections2;
  sections2.insert(2);
  sections2.insert(3);
  [_dataSource enqueueChangeset:{sections2, {}} constrainedSize:constrainedSize];

  [self waitUntilChangeCountIs:2 onChange:^(NSUInteger changeCount, CK::ComponentDataSource::State state) {
    if (changeCount == 1) {
      CK::ComponentDataSource::State expectedState = {
        {},
        {},
      };
      XCTAssertTrue(state == expectedState);
    } else if (changeCount == 2) {
      CK::ComponentDataSource::State expectedState = {
        {},
        {},
        {},
        {}
      };
      XCTAssertTrue(state == expectedState);
    } else {
      XCTFail(@"%lu", (unsigned long)changeCount);
    }
  }];
}

- (void)testInsertionThenUpdateOfItemInSeparateChangesets
{
  [self configureWithSingleEmptySection];

  Input::Items items1;
  items1.insert({0, 0}, @"Hello");
  [_dataSource enqueueChangeset:{{}, items1} constrainedSize:constrainedSize];

  Input::Items items2;
  items2.update({0, 0}, @"Batman");
  [_dataSource enqueueChangeset:{{}, items2} constrainedSize:constrainedSize];

  [self waitUntilChangeCountIs:2 onChange:^(NSUInteger changeCount, CK::ComponentDataSource::State state) {
    if (changeCount == 1) {
      CK::ComponentDataSource::State expectedState = {
        {
          {
            {@"Hello"}
          }
        }
      };
      XCTAssertTrue(state == expectedState);
    } else if (changeCount == 2) {
      CK::ComponentDataSource::State expectedState = {
        {
          {
            {@"Batman"}
          }
        }
      };
      XCTAssertTrue(state == expectedState);
    } else {
      XCTFail(@"%lu", (unsigned long)changeCount);
    }
  }];
}

- (void)testInsertionThenRemovalOfItemInSeparateChangesets
{
  [self configureWithSingleEmptySection];

  Input::Items items1;
  items1.insert({0, 0}, @"Hello");
  [_dataSource enqueueChangeset:{{}, items1} constrainedSize:constrainedSize];

  Input::Items items2;
  items2.remove({0, 0});
  [_dataSource enqueueChangeset:{{}, items2} constrainedSize:constrainedSize];

  [self waitUntilChangeCountIs:2 onChange:^(NSUInteger changeCount, CK::ComponentDataSource::State state) {
    if (changeCount == 1) {
      CK::ComponentDataSource::State expectedState = {
        {
          {
            {@"Hello"}
          }
        }
      };
      XCTAssertTrue(state == expectedState);
    } else if (changeCount == 2) {
      CK::ComponentDataSource::State expectedState = {
        {}
      };
      XCTAssertTrue(state == expectedState);
    }
  }];
}

@end

@interface CKComponentDataSourceEnumerationTests : XCTestCase
@end

@implementation CKComponentDataSourceEnumerationTests
{
  CKComponentDataSource *_dataSource;
  CKComponentDataSourceTestDelegate *_delegate;
}

- (void)setUp
{
  [super setUp];

  CKComponentDataSourceTestDelegate *delegate = [[CKComponentDataSourceTestDelegate alloc] init];

  CKComponentDataSource *dataSource = [[CKComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:[CKComponentConstantDenyingDecider class]];

  dataSource.delegate = delegate;

  _dataSource = dataSource;
  _delegate = delegate;
}

- (void)tearDown
{
  _dataSource = nil;
  _delegate = nil;
  [super tearDown];
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
{
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    if (_delegate.changeCount > changeCount) {
      XCTFail(@"%lu", (unsigned long)_delegate.changeCount);
    }
    return (_delegate.changeCount == changeCount);
  }), @"timeout");
}

- (void)configureWithMultipleSectionsAndItems
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({0, 1}, @"World");
  items.insert({1, 0}, @"Batman");
  items.insert({1, 1}, @"Robin");

  [_dataSource enqueueChangeset:{sections, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testIsComputingChanges
{
  [self configureWithMultipleSectionsAndItems];

  Input::Items batch1;
  batch1.insert({0, 2}, @"Catwoman");
  batch1.insert({2, 0}, @"Penguin");
  batch1.update({1, 1}, @"Joker");

  Input::Items batch2;
  batch2.remove({0,2});
  batch2.update({1,0 }, @"Alfred");

  XCTAssertFalse([_dataSource isComputingChanges]);
  [_dataSource enqueueChangeset:{batch1} constrainedSize:constrainedSize];
  XCTAssertTrue([_dataSource isComputingChanges]);
  [_dataSource enqueueChangeset:{batch2} constrainedSize:constrainedSize];
  XCTAssertTrue([_dataSource isComputingChanges]);
  [self waitUntilChangeCountIs:2];
  XCTAssertFalse([_dataSource isComputingChanges]);
}

@end

@interface CKComponentDataSourceReloadTest : XCTestCase <CKComponentProvider>
@end

@implementation CKComponentDataSourceReloadTest
{
  CKComponentDataSource *_dataSource;
  CKComponentDataSourceTestDelegate *_delegate;
}

- (void)setUp
{
  [super setUp];
  
  CKComponentDataSourceTestDelegate *delegate = [[CKComponentDataSourceTestDelegate alloc] init];
  
  CKComponentDataSource *dataSource = [[CKComponentDataSource alloc] initWithComponentProvider:[self class]
                                                                                       context:@"context"
                                                                                       decider:[CKComponentConstantApprovingDecider class]];
  
  dataSource.delegate = delegate;
  
  _dataSource = dataSource;
  _delegate = delegate;
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
{
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    if (_delegate.changeCount > changeCount) {
      XCTFail(@"%lu", (unsigned long)_delegate.changeCount);
    }
    return (_delegate.changeCount == changeCount);
  }), @"timeout");
}

- (void)testReloadCorrectlyEnqueuesUpdatesForTheContainedItems
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  
  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({0, 1}, @"World");
  items.insert({1, 0}, @"Batman");
  items.insert({1, 1}, @"Robin");
  
  [_dataSource enqueueChangeset:{sections, items} constrainedSize:{}];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
  
  NSMutableDictionary *capturedState = [NSMutableDictionary dictionary];
  [_dataSource enumerateObjectsUsingBlock:^(CKComponentDataSourceOutputItem *o, NSIndexPath *ip, BOOL *stop) {
    capturedState[ip] = o;
  }];
  [_dataSource enqueueReload];
  [self waitUntilChangeCountIs:1];
  
  for (CKComponentDataSourceTestDelegateChange *change in [_delegate changes]) {
    XCTAssertEqual(change.changeType, CKArrayControllerChangeTypeUpdate);
    XCTAssertEqualObjects(change.dataSourcePair, capturedState[change.sourceIndexPath]);
  }
  XCTAssertEqual([[_delegate changes] count], [capturedState count]);
}

- (void)testUpdateContextAndReloadUpdateTheContextForAllTheContainedItems
{
  Sections sections;
  sections.insert(0);
  
  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({0, 1}, @"World");
  
  [_dataSource enqueueChangeset:{sections, items} constrainedSize:{}];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
  
  NSString *newContext = @"newContext";
  [_dataSource updateContextAndEnqueueReload:newContext];
  [self waitUntilChangeCountIs:1];
  
  for (CKComponentDataSourceTestDelegateChange *change in [_delegate changes]) {
    XCTAssertEqualObjects(change.dataSourcePair.lifecycleManagerState.context, newContext);
  }
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKComponent newWithView:{[UIView class]} size:{}];
}

@end
