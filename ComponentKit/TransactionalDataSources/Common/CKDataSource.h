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

#import <ComponentKit/CKDataSourceProtocol.h>

@protocol CKComponentStateListener;
@protocol CKDataSourceStateModifying;

@protocol CKDataSourceChangesetModificationGenerator

-(id<CKDataSourceStateModifying>)changesetGenerationModificationForChangeset:(CKDataSourceChangeset *)changeset
                                                                    userInfo:(NSDictionary *)userInfo
                                                                         qos:(CKDataSourceQOS)qos
                                                               stateListener:(id<CKComponentStateListener>)stateListener;


@end

/** Transforms an input of model objects into CKComponentLayouts. All methods and callbacks are main thread only. */
@interface CKDataSource : NSObject <CKDataSourceProtocol>

/*
 Allows the overriding of the generation of a changeset modification. If this is not called it will
 defer to the default behavior.
 */
- (void)setChangesetModificationGenerator:(id<CKDataSourceChangesetModificationGenerator>)changesetModificationGenerator;

@end
