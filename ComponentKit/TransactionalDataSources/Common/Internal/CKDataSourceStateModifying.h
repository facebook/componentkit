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

@class CKDataSourceChange;
@class CKDataSourceState;

/** Protocol adopted by an object that can modify the data source state. */
@protocol CKDataSourceStateModifying <NSObject>
- (CKDataSourceChange *)changeFromState:(CKDataSourceState *)state;

// This method allows to extract an additional information relevant to modification
- (NSDictionary *)userInfo;
@end
