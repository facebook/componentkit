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

@interface CKDataSourceChangeset<__covariant ModelType> : NSObject
@end

/** A helper object that allows you to build changesets. */
@interface CKDataSourceChangesetBuilder<__covariant ModelType> : NSObject

+ (instancetype)dataSourceChangeset;
- (instancetype)withUpdatedItems:(NSDictionary<NSIndexPath *, ModelType> *)updatedItems;
- (instancetype)withRemovedItems:(NSSet *)removedItems;
- (instancetype)withRemovedSections:(NSIndexSet *)removedSections;
- (instancetype)withMovedItems:(NSDictionary<NSIndexPath *, NSIndexPath *> *)movedItems;
- (instancetype)withInsertedSections:(NSIndexSet *)insertedSections;
- (instancetype)withInsertedItems:(NSDictionary<NSIndexPath *, ModelType> *)insertedItems;
- (CKDataSourceChangeset<ModelType> *)build;

@end

namespace CK {
  auto itemsByIndexPathDescription(NSDictionary<NSIndexPath *, NSObject *> * const items, NSString * const title) -> NSString *;
}

#endif
