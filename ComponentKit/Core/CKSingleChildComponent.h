/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKTreeNodeProtocol.h>

/** Infra components with single child should inherit from this one. Please DO NOT use it directly. */
@interface CKSingleChildComponent : CKComponent <CKTreeNodeWithChildProtocol>
{
  // We need to access the iVar from `buildComponenTree:`, DO NOT use it otherwise.
  @package
  CKComponent *_child;
}
@end
