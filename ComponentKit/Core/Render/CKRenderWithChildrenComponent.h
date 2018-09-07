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
#import <ComponentKit/CKRenderComponentProtocol.h>

@interface CKRenderWithChildrenComponent : CKComponent <CKRenderWithChildrenComponentProtocol>

/*
 Returns a vector of 'CKComponent' children that will be rendered to the screen.

 If you override this method, you must override the `computeLayoutThatFits:` and provide a layout for these components.
 If you don't need a custom layout, you can just use CKFlexboxComponent instead.

 @param state The current state of the component.
 */
- (std::vector<CKComponent *>)renderChildren:(id)state;

@end
