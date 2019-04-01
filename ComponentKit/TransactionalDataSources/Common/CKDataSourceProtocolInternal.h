// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <ComponentKit/CKDataSourceProtocol.h>

@class CKDataSourceChange;

@protocol CKDataSourceProtocolInternal <CKDataSourceProtocol>

/**
 @param state initial state of dataSource, pass `nil` for an empty state.
 */
- (instancetype)initWithState:(CKDataSourceState *)state;

/**
 Apply a pre-computed `CKDataSourceChange` to the datasource.
 `NO` will be returned if the change is computed based on a outdated state.
 @param change pre-computed `CKDataSourceChange`
 @return YES if the applied change is legit.
 */
- (BOOL)applyChange:(CKDataSourceChange *)change;

/**
 Verify a pre-computed `CKDataSourceChange` without actually applying it to the datasource.
 `NO` will be returned if the change is computed based on a outdated state.
 @param change pre-computed `CKDataSourceChange`
 @return YES if the applied change is legit.
 */
- (BOOL)verifyChange:(CKDataSourceChange *)change;

@end
