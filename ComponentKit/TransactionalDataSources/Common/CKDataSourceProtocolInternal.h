// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

@protocol CKDataSourceProtocolInternal <NSObject>

/**
 @param configuration @see CKDataSourceConfiguration.
 @param state initial state of dataSource, pass `nil` for an empty state.
 */
- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
                                state:(CKDataSourceState *)state;

@end
