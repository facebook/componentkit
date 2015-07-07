/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKUpdateMode.h>

@protocol CKComponentProvider;
@protocol CKTransactionalComponentDataSourceListener;

@class CKTransactionalComponentDataSourceChangeset;
@class CKTransactionalComponentDataSourceConfiguration;
@class CKTransactionalComponentDataSourceState;

/** Transforms an input of model objects into CKComponentLayouts. All methods and callbacks are main thread only. */
@interface CKTransactionalComponentDataSource : NSObject

/** Designated initializer. */
- (instancetype)initWithConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration;

/** An immutable object representing the current state of the data source. */
- (CKTransactionalComponentDataSourceState *)state;

/**
 Applies the specified changes to the data source. If you apply a changeset synchronously while previous asynchronous
 changesets are still pending, they will all be applied synchronously before applying the new changeset.
 */
- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo;

/** Updates the configuration object, updating all existing components. */
- (void)updateConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo;

/**
 Regenerate all components in the data source. This can be useful when responding to changes to global singleton state
 that break the "components as a pure function of input" rule (for example, changes to UIAccessibility).
 */
- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo;

- (void)addListener:(id<CKTransactionalComponentDataSourceListener>)listener;
- (void)removeListener:(id<CKTransactionalComponentDataSourceListener>)listener;

@end
