/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTextComponent.h"

#import <memory>
#import <vector>

#import <ComponentKit/CKComponentInternal.h>

#import <ComponentKit/CKTextKitRenderer.h>
#import <ComponentKit/CKTextKitRendererCache.h>

#import <ComponentKit/CKInternalHelpers.h>

#import "CKTextComponentView.h"

static CK::TextKit::Renderer::Cache *sharedRendererCache()
{
  // This cache is sized arbitrarily
  static CK::TextKit::Renderer::Cache *__rendererCache (new CK::TextKit::Renderer::Cache("CKTextComponentRendererCache", 500, 0.2));
  return __rendererCache;
}

/**
 The concept here is that neither the component nor layout should ever have a strong reference to the renderer object.
 This is to reduce memory load when loading thousands and thousands of text components into memory at once.  Instead
 we maintain a LRU renderer cache that is queried via stack-allocated keys.
 */
static CKTextKitRenderer *rendererForAttributes(CKTextKitAttributes &attributes, CGSize constrainedSize)
{
  CK::TextKit::Renderer::Cache *cache = sharedRendererCache();
  const CK::TextKit::Renderer::Key key {
    attributes,
    constrainedSize
  };

  CKTextKitRenderer *renderer = cache->objectForKey(key);

  if (!renderer) {
    renderer =
    [[CKTextKitRenderer alloc]
     initWithTextKitAttributes:attributes
     constrainedSize:constrainedSize];
    cache->cacheObject(key, renderer, 1);
  }

  return renderer;
}

@implementation CKTextComponent
{
  CKTextKitAttributes _attributes;
  CKTextComponentAccessibilityContext _accessibilityContext;
}

+ (instancetype)newWithTextAttributes:(const CKTextKitAttributes &)attributes
                       viewAttributes:(const CKViewComponentAttributeValueMap &)viewAttributes
                              options:(const CKTextComponentOptions &)options
                                 size:(const CKComponentSize &)size
{
  CKTextKitAttributes copyAttributes = attributes.copy();
  CKViewComponentAttributeValueMap copiedMap = viewAttributes;
  copiedMap.insert({CKComponentViewAttribute::LayerAttribute(@selector(setDisplayMode:)), @(options.displayMode)});
  CKTextComponent *c = [super newWithView:{
    [CKTextComponentView class],
    std::move(copiedMap),
    {
      .isAccessibilityElement = options.accessibilityContext.isAccessibilityElement,
      .accessibilityLabel = options.accessibilityContext.accessibilityLabel.hasText()
      ? options.accessibilityContext.accessibilityLabel : ^{ return copyAttributes.attributedString.string; }
    }
  } size:size];
  if (c) {
    c->_attributes = copyAttributes;
    c->_accessibilityContext = options.accessibilityContext;
  }
  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  const CKTextKitRenderer *renderer = rendererForAttributes(_attributes, constrainedSize.max);
  return {
    self,
    constrainedSize.clamp({
      CKCeilPixelValue(renderer.size.width),
      CKCeilPixelValue(renderer.size.height)
    }),
    {}
  };
}

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent
{
  CK::Component::MountResult result = [super mountInContext:context
                                                       size:size
                                                   children:children
                                             supercomponent:supercomponent];
  CKTextComponentView *view = (CKTextComponentView *)result.contextForChildren.viewManager->view;
  CKTextKitRenderer *renderer = rendererForAttributes(_attributes, size);
  view.renderer = renderer;
  view.isAccessibilityElement = _accessibilityContext.isAccessibilityElement.boolValue;
  view.accessibilityLabel = _accessibilityContext.accessibilityLabel.hasText() ? _accessibilityContext.accessibilityLabel.value() : _attributes.attributedString.string;
  return result;
}

@end
