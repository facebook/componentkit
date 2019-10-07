/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKBaseRenderContext.h>

namespace CK {
  class ComponentSpecContext : public BaseRenderContext {
  public:
    ComponentSpecContext(const id<CKComponentProtocol> component): BaseRenderContext{component} {}
    ComponentSpecContext(): BaseRenderContext{} {}
  };

  static_assert(sizeof(ComponentSpecContext) == sizeof(BaseRenderContext), "Render context shouldn't add any data");
}
