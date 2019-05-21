/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

@protocol CKComponentProtocol;

namespace CK {
  class RenderContext {
    id<CKComponentProtocol> _component;

  public:
    RenderContext(const id<CKComponentProtocol> component): _component(component) {}
    RenderContext(): _component(nullptr) {}

    template <typename Component>
    friend inline auto component(const RenderContext &context) -> Component;
  };
}
