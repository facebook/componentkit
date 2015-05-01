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

@class CKComponent;

/**
 Protocol that classes provding the method that construct a component for a model need to implement.
 
 The Components infrastructure is decoupled from specific model and component classes by requiring product code to construct the
 correct component.
 */
@protocol CKComponentProvider <NSObject>

/**
 For the given model, an implementation is expected to create an instance of the correct component. Note that this
 method may be called concurrently on any thread. Therefore it should be threadsafe and should not use globals.
 @param model The model object for which we need a component.
 @param context The context parameter passed to the components infrastructure, for example the initializer of
 CKComponentTableViewDataSource. It is up to your implementation to pass whatever additional information you need to
 construct the correct component.
 */
+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context;

@end
