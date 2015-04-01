/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentDataSource.h"

#include <queue>

#import <ComponentKit/CKSectionedArrayController.h>

#import <ComponentKit/CKArgumentPrecondition.h>
#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>

#import "CKComponentDataSourceInputItem.h"
#import "CKComponentDataSourceOutputItem.h"
#import "CKComponentDeciding.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentLifecycleManagerAsynchronousUpdateHandler.h"
#import "CKComponentPreparationQueue.h"
#import "CKComponentPreparationQueueListener.h"

static const NSInteger kPreparationQueueDefaultWidth = 10;
typedef CKComponentLifecycleManager *(^CKComponentLifecycleManagerFactory)(void);

@interface CKComponentDataSource () <
CKComponentLifecycleManagerDelegate,
CKComponentLifecycleManagerAsynchronousUpdateHandler
>
@end

@implementation CKComponentDataSource
{
  id<CKComponentDeciding> _decider;
  id<NSObject> _context;

  /*
   Please see the discussion on why we need two arrays
   https://www.facebook.com/groups/574870245894928/permalink/645686615479957/

   The basic flow is

   Changes -> _inputArrayController -(async)-> Queue -(async)-> _outputArrayController -> delegate

   The _inputArrayController reflects the updated state to the subsequent changes
   that are coming in immediately since it is updated in sync.
   */
  CKSectionedArrayController *_outputArrayController;
  CKSectionedArrayController *_inputArrayController;
  CKComponentPreparationQueue *_componentPreparationQueue;
  std::queue<PreparationBatchID> _operationsInPreparationQueueTracker;
  CKComponentLifecycleManagerFactory _lifecycleManagerFactory;
}

CK_FINAL_CLASS([CKComponentDataSource class]);

#pragma mark - Lifecycle

- (instancetype)initWithLifecycleManagerFactory:(CKComponentLifecycleManagerFactory)lifecycleManagerFactory
                                        decider:(id<CKComponentDeciding>)decider
                                        context:(id<NSObject>)context
                           inputArrayController:(CKSectionedArrayController *)inputArrayController
                          outputArrayController:(CKSectionedArrayController *)outputArrayController
                               preparationQueue:(CKComponentPreparationQueue *)preparationQueue
{
  if (self = [super init]) {
    // Injected dependencies.
    _lifecycleManagerFactory = lifecycleManagerFactory;
    _decider = decider;
    _context = context;

    // Internal dependencies.
    _inputArrayController = inputArrayController;
    _outputArrayController = outputArrayController;
    _componentPreparationQueue = preparationQueue;
  }
  return self;
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                  decider:(id<CKComponentDeciding>)decider
{
  return [self initWithComponentProvider:componentProvider
                                 context:context
                                 decider:decider
                   preparationQueueWidth:kPreparationQueueDefaultWidth];
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                  decider:(id<CKComponentDeciding>)decider
                    preparationQueueWidth:(NSInteger)preparationQueueWidth
{
  CKComponentLifecycleManagerFactory lifecycleManagerFactory = ^{
    return [[CKComponentLifecycleManager alloc] initWithComponentProvider:componentProvider];
  };
  return [self initWithLifecycleManagerFactory:lifecycleManagerFactory
                                       decider:decider
                                       context:context
                          inputArrayController:[[CKSectionedArrayController alloc] init]
                         outputArrayController:[[CKSectionedArrayController alloc] init]
                              preparationQueue:[[CKComponentPreparationQueue alloc] initWithQueueWidth:preparationQueueWidth]];
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

#pragma mark - Public API

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@: %p; inputArrayController = %@; outputArrayController = %@>",
          [self class],
          self,
          _inputArrayController,
          _outputArrayController];
}

- (NSInteger)numberOfSections
{
  return [_outputArrayController numberOfSections];
}

- (NSInteger)numberOfObjectsInSection:(NSInteger)section
{
  return (NSInteger)[_outputArrayController numberOfObjectsInSection:section];
}

- (CKComponentDataSourceOutputItem *)objectAtIndexPath:(NSIndexPath *)indexPath
{
  return [_outputArrayController objectAtIndexPath:indexPath];
}

- (void)enumerateObjectsUsingBlock:(CKComponentDataSourceEnumerator)block
{
  if (block) {
    [_outputArrayController enumerateObjectsUsingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
      block(object, indexPath, stop);
    }];
  }
}

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)section usingBlock:(CKComponentDataSourceEnumerator)block
{
  if (block) {
    [_outputArrayController enumerateObjectsInSectionAtIndex:section
                                                  usingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
                                                    block(object, indexPath, stop);
                                                  }];
  }
}

- (std::pair<CKComponentDataSourceOutputItem *, NSIndexPath *>)firstObjectPassingTest:(CKComponentDataSourcePredicate)predicate
{
  return [_outputArrayController firstObjectPassingTest:predicate];
}

- (std::pair<CKComponentDataSourceOutputItem *, NSIndexPath *>)objectForUUID:(NSString *)UUID
{
  return [self firstObjectPassingTest:
          ^BOOL(CKComponentDataSourceOutputItem *object, NSIndexPath *indexPath, BOOL *stop) {
            return [[object UUID] isEqual:UUID];
          }];
}

- (void)enqueueReload
{
  __block CKArrayControllerInputItems items;
  [_inputArrayController enumerateObjectsUsingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
    items.update(indexPath, object);
  }];
  CKArrayControllerInputChangeset changeset(items);
  [self _enqueueChangeset:changeset];
}

- (void)updateContextAndEnqeueReload:(id)newContext
{
  CKAssertMainThread();
  if (_context != newContext) {
    _context = newContext;
    [self enqueueReload];
  }
}

/**
 External client is either CKComponentTableViewDataSource or the owner of the table view data source.
 They can't insert an CKComponentDataSourceInput b/c they don't have access to existing lifecycle managers that are in
 the _writeArrayController.

 Therefore we map() the input to wrap each item given to us.
 */
- (PreparationBatchID)enqueueChangeset:(const CKArrayControllerInputChangeset &)changeset constrainedSize:(const CKSizeRange &)constrainedSize
{
  CKArrayControllerInputChangeset::Mapper mapper =
  ^id<NSObject>(const CKArrayControllerIndexPath &indexPath, id<NSObject> object, CKArrayControllerChangeType type, BOOL *stop) {
    CKComponentLifecycleManager *lifecycleManager = nil;
    NSString *UUID = nil;
    if (type == CKArrayControllerChangeTypeInsert) {
      lifecycleManager = _lifecycleManagerFactory();
      lifecycleManager.asynchronousUpdateHandler = self;
      lifecycleManager.delegate = self;
      UUID = [[NSUUID UUID] UUIDString];
    }
    if (type == CKArrayControllerChangeTypeUpdate) {
      CKComponentDataSourceInputItem *oldInput = [_inputArrayController objectAtIndexPath:indexPath.toNSIndexPath()];
      lifecycleManager = [oldInput lifecycleManager];
      UUID = [oldInput UUID];
    }
    return [[CKComponentDataSourceInputItem alloc] initWithLifecycleManager:lifecycleManager
                                                                      model:object
                                                                    context:_context
                                                            constrainedSize:constrainedSize
                                                                       UUID:UUID ];
  };
  return [self _enqueueChangeset:changeset.map(mapper)];
}

- (PreparationBatchID)_enqueueChangeset:(const CKArrayControllerInputChangeset &)changeset
{
  auto output = [_inputArrayController applyChangeset:changeset];

  __block CKComponentPreparationInputBatch preparationQueueBatch;
  preparationQueueBatch.sections = output.getSections();

  __block BOOL batchContainsSectionInserts = NO;
  __block BOOL batchContainsUpdates = NO;
  __block BOOL batchContainsDeletions = NO;

  CKArrayControllerSections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeDelete) {
      batchContainsDeletions = YES;
    }

    if (type == CKArrayControllerChangeTypeInsert) {
      batchContainsSectionInserts = YES;
    }
  };

  NSMutableSet *insertedIndexPaths = [[NSMutableSet alloc] init];
  CKArrayControllerOutputItems::Enumerator itemsEnumerator =
  ^(const CKArrayControllerOutputChange &change, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeDelete) {
      batchContainsDeletions = YES;
    }
    if (type == CKArrayControllerChangeTypeUpdate) {
      batchContainsUpdates = YES;
    }
    if (type == CKArrayControllerChangeTypeInsert) {
      [insertedIndexPaths addObject:change.indexPath.toNSIndexPath()];
    }

    CKComponentDataSourceInputItem *before = change.before;
    CKComponentDataSourceInputItem *after = change.after;
    id componentCompliantModel = [_decider componentCompliantModel:[after model]];

    CKSizeRange constrainedSize = (type == CKArrayControllerChangeTypeDelete) ? CKSizeRange() : [after constrainedSize];
    CKComponentPreparationInputItem *queueItem =
    [[CKComponentPreparationInputItem alloc] initWithReplacementModel:[after model]
                                                     lifecycleManager:[after lifecycleManager]
                                                      constrainedSize:constrainedSize
                                                              oldSize:[before lifecycleManager].size
                                                                 UUID:[after UUID]
                                                            indexPath:change.indexPath.toNSIndexPath()
                                                           changeType:type
                                                          passthrough:(componentCompliantModel == nil)
                                                              context:[after context]];
    preparationQueueBatch.items.push_back(queueItem);
  };

  output.enumerate(sectionsEnumerator, itemsEnumerator);

  preparationQueueBatch.ID = batchID();
  _operationsInPreparationQueueTracker.push(preparationQueueBatch.ID);
  [_componentPreparationQueue enqueueBatch:preparationQueueBatch
                                     block:^(const CKArrayControllerSections &sections, PreparationBatchID ID, NSArray *outputBatch, BOOL isContiguousTailInsertion) {
                                       CKInternalConsistencyCheckIf(_operationsInPreparationQueueTracker.size() > 0, @"We dequeued more batches than what we enqueued something went really wrong.");
                                       CKInternalConsistencyCheckIf(_operationsInPreparationQueueTracker.front() == ID, @"Batches were executed out of order some were dropped on the floor.");
                                       _operationsInPreparationQueueTracker.pop();
                                       [self _componentPreparationQueueDidPrepareBatch:outputBatch
                                                                              sections:sections];
                                     }];
  return preparationQueueBatch.ID;
}

#pragma mark - Enqueued changes tracking

- (BOOL)isComputingChanges
{
  return !_operationsInPreparationQueueTracker.empty();
}

#pragma mark - Listeners to CKComponentPreparationQueue
- (void)addListener:(id<CKComponentPreparationQueueListener>)listener
{
  [_componentPreparationQueue addListener:listener];
}

- (void)removeListener:(id<CKComponentPreparationQueueListener>)listener
{
  [_componentPreparationQueue removeListener:listener];
}

#pragma mark - CKComponentPreparationQueueDelegate

- (void)_componentPreparationQueueDidPrepareBatch:(NSArray *)batch
                                         sections:(const CKArrayControllerSections &)sections
{
  CKAssertMainThread();

  CKArrayControllerInputItems items;

  for (CKComponentPreparationOutputItem *outputItem in batch) {
    CKArrayControllerChangeType type = [outputItem changeType];
    switch (type) {
      case CKArrayControllerChangeTypeUpdate: {
        items.update([outputItem indexPath], outputItem);
      }
        break;
      case CKArrayControllerChangeTypeInsert: {
        items.insert([outputItem indexPath], outputItem);
      }
        break;
      case CKArrayControllerChangeTypeDelete: {
        items.remove([outputItem indexPath]);
      }
        break;
      default:
        break;
    }
  }
  [self _processChangeset:{sections, items}];
}

- (void)_processChangeset:(const CKArrayControllerInputChangeset &)changeset
{
  CKArrayControllerInputChangeset::Mapper mapper =
  ^id<NSObject>(const CKArrayControllerIndexPath &indexPath, id<NSObject> object, CKArrayControllerChangeType type, BOOL *stop) {
    CKComponentPreparationOutputItem *item = (CKComponentPreparationOutputItem *)object;
    CKComponentLifecycleManager *lifecycleManager = [item lifecycleManager];
    CKComponentLifecycleManagerState lifecycleManagerState = [item lifecycleManagerState];
    if (![item isPassthrough]) {
      [lifecycleManager updateWithStateWithoutMounting:lifecycleManagerState];
    }
    return [[CKComponentDataSourceOutputItem alloc] initWithLifecycleManager:lifecycleManager
                                                       lifecycleManagerState:lifecycleManagerState
                                                                     oldSize:[item oldSize]
                                                                       model:[item replacementModel]
                                                                        UUID:[item UUID]];
  };
  auto mappedChangeset = changeset.map(mapper);
  
  __block CKComponentDataSourceChangeType changeTypes = 0;

  CKArrayControllerSections::Enumerator sectionEnumerator = ^(NSIndexSet *indexSet, CKArrayControllerChangeType changeType, BOOL *stop){
    switch (changeType) {
      case CKArrayControllerChangeTypeInsert: changeTypes |= CKComponentDataSourceChangeTypeInsertSections; break;
      case CKArrayControllerChangeTypeDelete: changeTypes |= CKComponentDataSourceChangeTypeDeleteSections; break;
      case CKArrayControllerChangeTypeMove: changeTypes |= CKComponentDataSourceChangeTypeMoveSections; break;
      default: CKFailAssert(@"Unexpected change type %lu", (unsigned long)changeType); break;
    }
  };
  
CKArrayControllerInputItems::Enumerator itemEnumerator =
  ^(NSInteger section, NSIndexSet *indexes, NSArray *objects, CKArrayControllerChangeType type, BOOL *stop) {
    switch (type) {
      case CKArrayControllerChangeTypeInsert: changeTypes |= CKComponentDataSourceChangeTypeInsertRows; break;
      case CKArrayControllerChangeTypeDelete: changeTypes |= CKComponentDataSourceChangeTypeDeleteRows; break;
      case CKArrayControllerChangeTypeMove: changeTypes |= CKComponentDataSourceChangeTypeMoveRows; break;
      case CKArrayControllerChangeTypeUpdate: {
        [objects enumerateObjectsUsingBlock:^(CKComponentDataSourceOutputItem *obj, NSUInteger idx, BOOL *innerStop) {
          if (!CGSizeEqualToSize([obj oldSize], [obj lifecycleManagerState].layout.size)) {
            changeTypes |= CKComponentDataSourceChangeTypeUpdateSize;
            *innerStop = YES;
          }
        }];
        break;
      }
      default: CKFailAssert(@"Unexpected change type %lu", (unsigned long)type); break;
    }
  };
  mappedChangeset.enumerate(sectionEnumerator, itemEnumerator);
  
  [_delegate componentDataSource:self
               hasChangesOfTypes:changeTypes
             changesetApplicator:^{
               return [_outputArrayController applyChangeset:mappedChangeset];
             }];
}

#pragma mark - CKComponentLifecycleManagerDelegate

- (void)componentLifecycleManager:(CKComponentLifecycleManager *)manager
       sizeDidChangeWithAnimation:(const CKComponentBoundsAnimation &)animation
{
  __block CKComponentDataSourceOutputItem *matchingObject;
  __block NSIndexPath *matchingIndexPath;
  [_outputArrayController enumerateObjectsUsingBlock:^(CKComponentDataSourceOutputItem *object, NSIndexPath *indexPath, BOOL *stop) {
    if (object.lifecycleManager == manager) {
      matchingObject = object;
      matchingIndexPath = indexPath;
      *stop = YES;
    }
  }];
  if (matchingObject) {
    [_delegate componentDataSource:self
            didChangeSizeForObject:matchingObject
                       atIndexPath:matchingIndexPath
                         animation:animation];
  }
}

#pragma mark - CKComponentLifecycleManagerAsynchronousUpdateHandler

- (void)handleAsynchronousUpdateForComponentLifecycleManager:(CKComponentLifecycleManager *)manager
{
  std::pair<id<NSObject>, NSIndexPath *> itemToUpdate = [_inputArrayController firstObjectPassingTest:^BOOL(CKComponentDataSourceInputItem *object, NSIndexPath *indexPath, BOOL *stop) {
    return object.lifecycleManager == manager;
  }];
  // There is a possibility that when we enqueue the update, a deletion has already
  // been enqueued for the same item, in this case we won't find a corresponding
  // item in the input array.
  if (itemToUpdate.first && itemToUpdate.second ) {
    CKArrayControllerInputItems items;
    items.update(itemToUpdate.second, itemToUpdate.first);
    [self _enqueueChangeset:{items}];
  }
}

#pragma mark - Utilities

/** @return the UUID for a changeset sent to the preparationQueue */
static PreparationBatchID batchID()
{
  CKCAssertMainThread();
  static PreparationBatchID batchID = 0;
  return batchID++;
}

@end
