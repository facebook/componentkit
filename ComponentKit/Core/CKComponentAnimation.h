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

#import <ComponentKit/CKComponentAnimationHooks.h>

@class CAAnimation;
@class CKComponent;

struct CKComponentAnimation {

  /**
   Creates a CKComponentAnimation that applies a CAAnimation to a CKComponent, on the layer found at layerPath. The
   layer of the view is used when layerPath is nil.
   
   @note The CKComponent must create a UIView via its view configuration; or, it must be a CKCompositeComponent that
   renders to a component that creates a view. The view must have a CALayer at the keypath that corresponds to
   layerPath; or, it must be nil.

   @example Animate the position of a component: {myComponent, [CABasicAnimation animationWithKeypath:@"position"]}
   
   @example Suppose the component has a CAShapeLayer as the mask of the view's layer. The path of the mask could be
   animated with: {myComponent, [CABasicAnimation animationWithKeypath:@"path"], "layer.mask"}
   
   @param component A CKComponent that will be animated.
   @param animation A CAAnimation to apply on the component's layer.
   @param layerPath A key path to a sublayer of the component's view. Defaults to nil.
   */
  CKComponentAnimation(CKComponent *component, CAAnimation *animation, NSString *layerPath = nil);
  
  /** Creates a completely custom animation with arbitrary hooks. */
  CKComponentAnimation(const CKComponentAnimationHooks &hooks);

  id willRemount() const;
  id didRemount(id context) const;
  void cleanup(id context) const;

private:
  CKComponentAnimationHooks hooks;
};
