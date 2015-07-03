/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <vector>

#import <Foundation/Foundation.h>

#import <ComponentKit/CKArrayControllerChangeType.h>
#import <ComponentKit/CKArrayControllerChangeset.h>

#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentLifecycleManager.h>
#import <ComponentKit/CKComponentPreparationQueueTypes.h>
#import <ComponentKit/CKDimension.h>

@protocol CKComponentPreparationItem <NSObject>

@property (readonly, nonatomic, strong) id<NSObject> replacementModel;

@property (readonly, nonatomic, strong) CKComponentLifecycleManager *lifecycleManager;

@property (readonly, nonatomic, assign) CGSize oldSize;

@property (readonly, nonatomic, copy) NSString *UUID;

@property (readonly, nonatomic, copy) NSIndexPath *sourceIndexPath;

@property (readonly, nonatomic, copy) NSIndexPath *destinationIndexPath;

@property (readonly, nonatomic, assign) CKArrayControllerChangeType changeType;

@property (readonly, nonatomic, assign, getter = isPassthrough) BOOL passthrough;

@property (readonly, nonatomic, strong) id<NSObject> context;

@end

@interface CKComponentPreparationInputItem : NSObject <
CKComponentPreparationItem
>

- (instancetype)initWithReplacementModel:(id<NSObject>)replacementModel
                        lifecycleManager:(CKComponentLifecycleManager *)lifecycleManager
                         constrainedSize:(CKSizeRange)constrainedSize
                                 oldSize:(CGSize)oldSize
                                    UUID:(NSString *)UUID
                         sourceIndexPath:(NSIndexPath *)sourceIndexPath
                    destinationIndexPath:(NSIndexPath *)destinationIndexPath
                              changeType:(CKArrayControllerChangeType)changeType
                             passthrough:(BOOL)passthrough
                                 context:(id<NSObject>)context;

- (CKSizeRange)constrainedSize;

@end

@interface CKComponentPreparationOutputItem : NSObject <
CKComponentPreparationItem
>

- (instancetype)initWithReplacementModel:(id<NSObject>)replacementModel
                        lifecycleManager:(CKComponentLifecycleManager *)lifecycleManager
                   lifecycleManagerState:(CKComponentLifecycleManagerState)lifecycleManagerState
                                 oldSize:(CGSize)oldSize
                                    UUID:(NSString *)UUID
                         sourceIndexPath:(NSIndexPath *)sourceIndexPath
                    destinationIndexPath:(NSIndexPath *)destinationIndexPath
                              changeType:(CKArrayControllerChangeType)changeType
                             passthrough:(BOOL)passthrough
                                 context:(id<NSObject>)context;

- (CKComponentLifecycleManagerState)lifecycleManagerState;

@end

struct CKComponentPreparationInputBatch {
  PreparationBatchID ID;
  CKArrayControllerSections sections;
  std::vector<CKComponentPreparationInputItem *> items;
  BOOL isContiguousTailInsertion;
};

@protocol CKComponentPreparationQueueListener;
/**
 The preparation queue processes batches of changes in the background. 
 For each item in the batch the corresponding components will be generated and layed out concurrently.
 */
@interface CKComponentPreparationQueue : NSObject

typedef void (^CKComponentPreparationQueueCallback)(const CKArrayControllerSections &sections, PreparationBatchID ID, NSArray *batch, BOOL isContiguousTailInsertion);

/**
 @param queueWidth Must be greater than 0, this is the maximum number of items computed concurrently in a batch
 */
- (instancetype)initWithQueueWidth:(NSInteger)queueWidth;

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

/**
 @param batch The batch of input items to process.
 @param block Called with the output items. The block is invoked on the main queue and the order of items in the output array is undefined.
 */
- (void)enqueueBatch:(const CKComponentPreparationInputBatch &)batch
               block:(CKComponentPreparationQueueCallback)block;

/**
 Allows adding/removing listeners for CKComponentPreparationQueue events.
 */
- (void)addListener:(id<CKComponentPreparationQueueListener>)listener;
- (void)removeListener:(id<CKComponentPreparationQueueListener>)listener;

@end
