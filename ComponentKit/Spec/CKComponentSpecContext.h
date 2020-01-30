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

#import <ComponentKit/CKBaseRenderContext.h>
#import <ComponentKit/CKPropBitmap.h>

@class CKComponent;

namespace CK {

  namespace BuilderDetails {
    template <template <PropsBitmapType> class, PropsBitmapType>
    class BuilderBase;
  }

  class ComponentSpecContext : public BaseRenderContext {
  public:
    ComponentSpecContext(const id<CKComponentProtocol> component): BaseRenderContext{component} {}
    ComponentSpecContext(): BaseRenderContext{} {}

  private:
    template <template <BuilderDetails::PropsBitmapType> class, BuilderDetails::PropsBitmapType>
    friend class BuilderDetails::BuilderBase;

    void declareKey(id key, CKComponent *component) const {
      // Do nothing here - OSS.
    }
  };

  static_assert(sizeof(ComponentSpecContext) == sizeof(BaseRenderContext), "Render context shouldn't add any data");
}

#endif
