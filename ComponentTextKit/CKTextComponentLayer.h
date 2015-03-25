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

@class CKTextComponentLayerHighlighter;
@class CKTextKitRenderer;

/**
 An implementation detail of the CKTextComponentView.  You should rarely, if ever have to deal directly with this class.
 */
@interface CKTextComponentLayer : CKAsyncLayer

@property (nonatomic, strong) CKTextKitRenderer *renderer;

@property (nonatomic, strong, readonly) CKTextComponentLayerHighlighter *highlighter;

@end
