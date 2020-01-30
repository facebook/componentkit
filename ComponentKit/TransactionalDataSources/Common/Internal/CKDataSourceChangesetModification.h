/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKDataSourceStateModifying.h>

@class CKComponentScopeRoot;
@class CKDataSourceChangeset;
@class CKDataSourceItem;

@protocol CKComponentStateListener;

typedef NS_ENUM(NSUInteger, CKDataSourceChangesetModificationItemType) {
  CKDataSourceChangesetModificationItemTypeInsert,
  CKDataSourceChangesetModificationItemTypeUpdate,
};

@protocol CKDataSourceChangesetModificationItemGenerator

- (CKDataSourceItem *)buildDataSourceItemForPreviousRoot:(CKComponentScopeRoot *)previousRoot
                                            stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                                               sizeRange:(const CKSizeRange &)sizeRange
                                           configuration:(CKDataSourceConfiguration *)configuration
                                                   model:(id)model
                                                 context:(id)context
                                                itemType:(CKDataSourceChangesetModificationItemType)itemType;

@end

@interface CKDataSourceChangesetModification : NSObject <CKDataSourceStateModifying>

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
                              qos:(CKDataSourceQOS)qos
          shouldValidateChangeset:(BOOL)shouldValidateChangeset;

@property (nonatomic, readonly, strong) CKDataSourceChangeset *changeset;

- (void)setItemGenerator:(id<CKDataSourceChangesetModificationItemGenerator>)itemGenerator;
- (BOOL)shouldSortInsertedItems;
- (BOOL)shouldSortUpdatedItems;

@end

namespace CK {
  auto invalidIndexesForInsertionInArray(NSArray *const a, NSIndexSet *const is) -> NSIndexSet *;
  auto invalidIndexesForRemovalFromArray(NSArray *const a, NSIndexSet *const is) -> NSIndexSet *;
}

#endif
