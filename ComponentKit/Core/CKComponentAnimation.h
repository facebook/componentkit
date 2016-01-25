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
   Creates a CKComponentAnimation that applies a CAAnimation to a CKComponent on the layer found at layerPath.
   
   @note The CKComponent must create a UIView via its view configuration; or, it must be a CKCompositeComponent that
   renders to a component that creates a view. The view must have a CALayer at the keypath that corresponds to 
   layerPath.
   
   @example Suppose the component has a CAShapeLayer as the mask of the view's layer. The path of the mask could be animated
   with: {myComponent, [CABasicAnimation animationWithKeypath:@"path"], "layer.mask"}
   */
  CKComponentAnimation(CKComponent* component, CAAnimation* animation, NSString* layerPath);
  
  /**
   Creates a CKComponentAnimation that applies a CAAnimation to a CKComponent on the layer of the view.
   
   @example {myComponent, [CABasicAnimation animationWithKeypath:@"position"]}
   
   @see CKComponentAnimation(CKComponent* component, CAAnimation* animation, NSString* layerPath)
   */
  CKComponentAnimation(CKComponent *component, CAAnimation *animation);

  
  /** Creates a completely custom animation with arbitrary hooks. */
  CKComponentAnimation(const CKComponentAnimationHooks &hooks);

  id willRemount() const;
  id didRemount(id context) const;
  void cleanup(id context) const;

private:
  CKComponentAnimationHooks hooks;
};
