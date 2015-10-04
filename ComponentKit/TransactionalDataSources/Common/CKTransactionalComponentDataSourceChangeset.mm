/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceChangeset.h"
#import "CKTransactionalComponentDataSourceChangesetInternal.h"
#import "CKAssert.h"
#import "CKArgumentPrecondition.h"

@implementation CKTransactionalComponentDataSourceChangeset

- (instancetype)initWithUpdatedItems:(NSDictionary *)updatedItems
                        removedItems:(NSSet *)removedItems
                     removedSections:(NSIndexSet *)removedSections
                          movedItems:(NSDictionary *)movedItems
                       movedSections:(NSDictionary *)movedSections
                    insertedSections:(NSIndexSet *)insertedSections
                       insertedItems:(NSDictionary *)insertedItems
{
  if (self = [super init]) {
    _updatedItems = [updatedItems copy] ?: @{};
    _removedItems = [removedItems copy] ?: [NSSet set];
    _removedSections = [removedSections copy] ?: [NSIndexSet indexSet];
    _movedItems = [movedItems copy] ?: @{};
    _movedSections = [movedSections copy] ?: @{};
    _insertedSections = [insertedSections copy] ?: [NSIndexSet indexSet];
    _insertedItems = [insertedItems copy] ?: @{};
  }
  return self;
}

@end

@implementation CKTransactionalComponentDataSourceChangesetBuilder
{
  NSDictionary *_updatedItems;
  NSSet *_removedItems;
  NSIndexSet *_removedSections;
  NSDictionary *_movedItems;
  NSDictionary *_movedSections;
  NSIndexSet *_insertedSections;
  NSDictionary *_insertedItems;
}

+ (instancetype)transactionalComponentDataSourceChangeset { return [[self alloc] init]; }
- (instancetype)withUpdatedItems:(NSDictionary *)updatedItems { _updatedItems = updatedItems; return self;}
- (instancetype)withRemovedItems:(NSSet *)removedItems { _removedItems = removedItems; return self; }
- (instancetype)withRemovedSections:(NSIndexSet *)removedSections { _removedSections = removedSections; return self; }
- (instancetype)withMovedItems:(NSDictionary *)movedItems { _movedItems = movedItems; return self; }
- (instancetype)withMovedSections:(NSDictionary *)movedSections { _movedSections = movedSections; return self; }
- (instancetype)withInsertedSections:(NSIndexSet *)insertedSections { _insertedSections = insertedSections; return self; }
- (instancetype)withInsertedItems:(NSDictionary *)insertedItems { _insertedItems = insertedItems; return self; }

- (CKTransactionalComponentDataSourceChangeset *)build
{
  return [[CKTransactionalComponentDataSourceChangeset alloc] initWithUpdatedItems:_updatedItems
                                                                      removedItems:_removedItems
                                                                   removedSections:_removedSections
                                                                        movedItems:_movedItems
                                                                     movedSections:_movedSections
                                                                  insertedSections:_insertedSections
                                                                     insertedItems:_insertedItems];
}

@end

#pragma mark -

namespace CKChangesetBuilder {
  namespace Verb {
    enum Type { None, Update, Insert, Remove, Move };
  }
  namespace Element {
    enum Type { None, Section, Item };
  }
}

using namespace CKChangesetBuilder;

@interface CKTransactionalComponentDataSourceChangesetDSLBuilder ()
@property (nonatomic, assign) Verb::Type verb;
@property (nonatomic, assign) Element::Type element;
@property (nonatomic, strong) id object;
@property (nonatomic, assign) NSNumber *sectionIndex;
@property (nonatomic, strong) NSIndexPath *itemIndexPath;
@property (nonatomic, assign) NSNumber *sectionMoveIndex;
@property (nonatomic, strong) NSIndexPath *itemMoveIndexPath;
- (void)storeIfExpressionComplete;
- (void)reset;
@end

@implementation CKTransactionalComponentDataSourceChangesetDSLBuilder
{
  NSMutableDictionary *_updatedItems;
  NSMutableSet *_removedItems;
  NSMutableIndexSet *_removedSections;
  NSMutableDictionary *_movedItems;
  NSMutableDictionary *_movedSections;
  NSMutableIndexSet *_insertedSections;
  NSMutableDictionary *_insertedItems;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _updatedItems = [NSMutableDictionary dictionary];
    _movedItems = [NSMutableDictionary dictionary];
    _movedSections = [NSMutableDictionary dictionary];
    _insertedItems = [NSMutableDictionary dictionary];
    _removedItems = [NSMutableSet set];
    _removedSections = [NSMutableIndexSet indexSet];
    _insertedSections = [NSMutableIndexSet indexSet];
  }
  return self;
}

+ (CKTransactionalComponentDataSourceChangeset*)build:(void(^)(CKTransactionalComponentDataSourceChangesetDSLBuilder *builder))block
{
  CKTransactionalComponentDataSourceChangesetDSLBuilder *builder = [[self alloc] init];
  [builder build:block];
  return builder.build;
}

- (instancetype)build:(void(^)(CKTransactionalComponentDataSourceChangesetDSLBuilder *builder))block {
  block(self);
  return self;
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *)update {
  CKInternalConsistencyCheckIf(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Update;
  return self;
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *)insert {
  CKInternalConsistencyCheckIf(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Insert;
  return self;
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *)remove {
  CKInternalConsistencyCheckIf(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Remove;
  return self;
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *)move {
  CKInternalConsistencyCheckIf(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Move;
  return self;
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *)section {
  CKInternalConsistencyCheckIf(self.verb != Verb::None, @"Expression contains noun, but no verb");
  CKInternalConsistencyCheckIf(self.element == Element::None, @"Expression contains >1 element");
  self.element = Element::Section;
  return self;
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *)at {
  CKInternalConsistencyCheckIf(self.verb != Verb::None, @"Expression contains no verb");
  CKInternalConsistencyCheckIf((self.element == Element::Section && !self.sectionIndex) ||
                               (self.element == Element::Item && !self.itemIndexPath) ||
                               (self.verb == Verb::Update),
                               @"Expression already contains an index, or indexPath");
  return self;
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *)to {
  CKInternalConsistencyCheckIf(self.verb == Verb::Move, @"Preposition only valid for move operation");
  CKInternalConsistencyCheckIf((self.element == Element::Section && self.sectionIndex) ||
                               (self.element == Element::Item && self.itemIndexPath),
                               @"Expression contains no source index or indexPath for move");
  return self;
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *)with {
  CKInternalConsistencyCheckIf(self.verb == Verb::Update, @"Preposition only valid for update operation");
  CKInternalConsistencyCheckIf(self.itemIndexPath, @"Now indexPath for update operation");
  return self;
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *(^)(id))item {
  CKInternalConsistencyCheckIf(self.verb != Verb::None, @"Expression contains no verb");
  CKInternalConsistencyCheckIf(self.element == Element::None, @"Expression already contains a noun");
  self.element = Element::Item;
  return ^(id item) {
    CKInternalConsistencyCheckIf(self.verb != Verb::Insert || item, @"Object required for insert operation");
    self.object = item;
    [self storeIfExpressionComplete];
    return self;
  };
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *(^)(NSUInteger))index {
  CKInternalConsistencyCheckIf(self.element == Element::Section, @"Index only valid for section operations");
  return ^(NSUInteger index) {
    switch (self.verb) {
      case Verb::Insert:
      case Verb::Remove:
        self.sectionIndex = @(index);
        break;
      case Verb::Move:
        self.sectionIndex ? self.sectionMoveIndex = @(index) : self.sectionIndex = @(index);
        break;
      default:
        NSAssert(NO, @"Not valid for Update");
        break;
    }
    [self storeIfExpressionComplete];
    return self;
  };
}

- (CKTransactionalComponentDataSourceChangesetDSLBuilder *(^)(NSIndexPath *))indexPath {
  CKInternalConsistencyCheckIf(self.element == Element::Item || self.verb == Verb::Update, @"Expression contains no object");
  return ^(NSIndexPath *indexPath) {
    switch (self.verb) {
      case Verb::Insert:
      case Verb::Remove:
      case Verb::Update:
        self.itemIndexPath = indexPath;
        break;
      case Verb::Move:
        self.itemIndexPath ? self.itemMoveIndexPath = indexPath : self.itemIndexPath = indexPath;
        break;
      default:
        break;
    }
    [self storeIfExpressionComplete];
    return self;
  };
}

- (void)storeIfExpressionComplete
{
  CKInternalConsistencyCheckIf(self.verb != Verb::None, @"Expression contains no verb");
  CKInternalConsistencyCheckIf(self.element != Element::None || self.verb == Verb::Update, @"Expression contains no noun");
  switch (self.verb)
  {
    case Verb::Update:
      /** Update item */
      if (self.object && self.itemIndexPath) {
        CKConditionalAssert(!_updatedItems[self.itemIndexPath],
                            @"Already object %@ for indexPath %@",
                            self.object, self.itemIndexPath);
        _updatedItems[self.itemIndexPath] = self.object;
        [self reset];
      }
      break;

    case Verb::Insert:
      /** Insert section */
      if (self.element == Element::Section && self.sectionIndex)
      {
        CKConditionalAssert(![_insertedSections containsIndex:self.sectionMoveIndex.unsignedIntegerValue],
                            @"Inserted sections already contains index %@", self.sectionIndex);
        [_insertedSections addIndex:self.sectionMoveIndex.unsignedIntegerValue];
        [self reset];
      }

      /** Insert item */
      else if (self.element == Element::Item && self.object && self.itemIndexPath)
      {
        CKConditionalAssert(!_insertedItems[self.itemIndexPath],
                            @"Inserted items already contains object %@ for indexPath %@",
                            self.object, self.itemIndexPath);
        _insertedItems[self.itemIndexPath] = self.object;
        [self reset];
      }
      break;

    case Verb::Move:
      /** Move section */
      if (self.element == Element::Section && self.sectionIndex && self.sectionMoveIndex)
      {
        CKConditionalAssert(!_movedSections[self.sectionIndex],
                            @"Section move already exists from %@ to %ld",
                            self.sectionIndex, self.sectionMoveIndex);
        _movedSections[self.sectionIndex] = self.sectionMoveIndex;
        [self reset];
      }

      /** Move item */
      else if (self.element == Element::Item && self.itemIndexPath && self.itemMoveIndexPath)
      {
        CKConditionalAssert(!_movedItems[self.itemIndexPath],
                            @"Item move already exists from %@ to %@",
                            self.itemIndexPath, self.itemMoveIndexPath);
        _movedItems[self.itemIndexPath] = self.itemMoveIndexPath;
        [self reset];
      }
      break;

    case Verb::Remove:
      /** Remove section */
      if (self.element == Element::Section && self.sectionIndex)
      {
        CKConditionalAssert(![_removedSections containsIndex:self.sectionIndex.unsignedIntegerValue],
                            @"Section %@ already stored for removal", self.sectionIndex);
        [_removedSections addIndex:self.sectionIndex.unsignedIntegerValue];
        [self reset];
      }

      /** Remove item */
      else if (self.element == Element::Item && self.itemIndexPath)
      {
        CKConditionalAssert(![_removedItems member:self.itemIndexPath],
                            @"Item at indexPath %@ already stored for removal",
                            self.itemIndexPath);
        [_removedItems addObject:self.itemIndexPath];
        [self reset];
      }
      break;

    default:
      break;
  }
}

- (void)reset
{
  self.verb = Verb::None;
  self.element = Element::None;
  self.object = nil;
  self.sectionIndex = self.sectionMoveIndex = nil;
  self.itemIndexPath = self.itemMoveIndexPath = nil;
}

- (CKTransactionalComponentDataSourceChangeset *)build
{
  return [[CKTransactionalComponentDataSourceChangeset alloc] initWithUpdatedItems:_updatedItems
                                                                      removedItems:_removedItems
                                                                   removedSections:_removedSections
                                                                        movedItems:_movedItems
                                                                     movedSections:_movedSections
                                                                  insertedSections:_insertedSections
                                                                     insertedItems:_insertedItems];
}

@end
