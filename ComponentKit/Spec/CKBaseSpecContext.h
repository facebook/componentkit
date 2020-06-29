/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

@protocol CKComponentProtocol;

class CKActionBase;

namespace CK {
  class BaseSpecContext {

  protected:
    id<CKComponentProtocol> _component;

    BaseSpecContext(const BaseSpecContext &) = default;
    BaseSpecContext& operator=(const BaseSpecContext &) = default;

  public:
    BaseSpecContext(const id<CKComponentProtocol> component): _component(component) {}
    BaseSpecContext(): _component(nullptr) {}

    BaseSpecContext(BaseSpecContext &&) = default;
    BaseSpecContext& operator=(BaseSpecContext&&) = default;

    template <typename Component>
    friend inline auto component(const BaseSpecContext &context) -> Component;

    friend class ::CKActionBase;
  };
}

#endif
