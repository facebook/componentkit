/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKAsyncLayer.h>

@interface CKAsyncLayer (Subclass)

/**
 Called on the main thread just before an async display operation is begun.
 Override in a subclass if you desire.

 @param drawParameters The draw parameters returned from -drawParameters that will be passed to the async operation.
 @return A CGImageRef if you want to specify that async display should be skipped; the returned CGImageRef will be used instead.
 */
- (id)willDisplayAsynchronouslyWithDrawParameters:(id<NSObject>)drawParameters;

/**
 Called on the main thread after an async display has successfully completed, just before the new rendered contents
 are applied via setContents:. Override in a subclass if you desire.

 @param newContents The resulting CGImageRef that will be assigned to the layer's contents property.
 @param drawParameters The parameters used to asynchronously display the layer.
 */
- (void)didDisplayAsynchronously:(id)newContents withDrawParameters:(id<NSObject>)drawParameters;

@end
