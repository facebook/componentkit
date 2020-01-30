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

#import <ComponentKit/CKDataSourceQOS.h>

@class CKDataSourceChange;
@class CKDataSourceState;

/** Protocol adopted by an object that can modify the data source state. */
@protocol CKDataSourceStateModifying <NSObject>
- (CKDataSourceChange *)changeFromState:(CKDataSourceState *)state;

// This method allows to extract an additional information relevant to modification
- (NSDictionary *)userInfo;

/**
 @return The QOS to *enforced* on the queue processing the application of current id<CKDataSourceStateModifying> object.
 @discussion This QOS overrides any QOS specified in the queue it runs on, unless it's applied on the main queue.
*/
- (CKDataSourceQOS)qos;

@end

#endif
