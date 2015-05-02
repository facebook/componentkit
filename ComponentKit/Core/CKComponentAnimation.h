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
   Creates a CKComponentAnimation that applies a CAAnimation to a CKComponent.

   @note The CKComponent must create a UIView via its view configuration; or, it must be a CKCompositeComponent that
   renders to a component that creates a view.

   @example {myComponent, [CABasicAnimation animationWithKeypath:@"position"]}
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
