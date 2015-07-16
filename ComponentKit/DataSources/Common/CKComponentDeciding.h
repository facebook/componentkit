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

@protocol CKComponentDeciding <NSObject>

/*
 * Returns a component compliant model if possible
 * Nil otherwise
 */
- (id)componentCompliantModel:(id)model;

/*
 * In case the model is not component compliant, returns a string explaining why
 * Otherwise returns nil. Used for logging and debugging.
 */
- (NSString *)componentComplianceReason:(id)model;

@end
