/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */


#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentOwner.h>

@interface CKSingleChildComponent : CKComponent <CKComponentOwner>

/**
 Returns a child component that needs to be rendered from this component.

 @param state The current state of the component.
 */
- (CKComponent *)render:(id)state;

@end
