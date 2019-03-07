// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

@class CKDataSourceChange;

@protocol CKDataSourceProtocolInternal <NSObject>

/**
 @param configuration @see CKDataSourceConfiguration.
 @param state initial state of dataSource, pass `nil` for an empty state.
 */
- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
                                state:(CKDataSourceState *)state;

/**
 Apply a pre-computed `CKDataSourceChange` to the datasource.
 `NO` will be returned if the change is computed based on a outdated state.
 @param change pre-computed `CKDataSourceChange`
 @return YES if the applied change is legit.
 */
- (BOOL)applyChange:(CKDataSourceChange *)change;

@end
