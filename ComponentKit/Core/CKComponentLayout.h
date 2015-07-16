/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <utility>
#import <vector>

#import <UIKit/UIKit.h>

#import <ComponentKit/CKAssert.h>

@class CKComponent;

struct CKComponentLayoutChild;

/** Deletes the target off the main thread; important since component layouts are large recursive structures. */
struct CKOffMainThreadDeleter {
  void operator()(std::vector<CKComponentLayoutChild> *target);
};

/** Represents the computed size of a component, as well as the computed sizes and positions of its children. */
struct CKComponentLayout {
  CKComponent *component;
  CGSize size;
  std::shared_ptr<const std::vector<CKComponentLayoutChild>> children;

  CKComponentLayout(CKComponent *c, CGSize s, std::vector<CKComponentLayoutChild> ch = {})
  : component(c), size(s), children(new std::vector<CKComponentLayoutChild>(std::move(ch)), CKOffMainThreadDeleter()) {
    CKCAssertNotNil(c, @"Nil components are not allowed");
  };

  CKComponentLayout()
  : component(nil), size({0, 0}), children(new std::vector<CKComponentLayoutChild>(), CKOffMainThreadDeleter()) {};
};

struct CKComponentLayoutChild {
  CGPoint position;
  CKComponentLayout layout;
};

/** Recursively mounts the layout in the view, returning a set of the mounted components. */
NSSet *CKMountComponentLayout(const CKComponentLayout &layout, UIView *view, CKComponent *supercomponent = nil);
