/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <string>
#import <unordered_map>

#import <UIKit/UIKit.h>

#import <ComponentKit/ComponentMountContext.h>
#import <ComponentKit/ComponentViewManager.h>
#import <ComponentKit/ComponentViewReuseUtilities.h>
#import <ComponentKit/CKComponentAccessibility.h>
#import <ComponentKit/CKComponentViewAttribute.h>
#import <ComponentKit/CKComponentViewClass.h>
#import <ComponentKit/CKContainerWrapper.h>


typedef void (^CKComponentViewReuseBlock)(UIView *);

/**
 A CKComponentViewConfiguration specifies the class of a view and the attributes that should be applied to it.
 Initialize a configuration with brace syntax, for example:

 {[UIView class]}
 {[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}, {@selector(setAlpha:), @0.5}}}
 */
struct CKComponentViewConfiguration {

  CKComponentViewConfiguration() noexcept;

  CKComponentViewConfiguration(CKComponentViewClass &&cls,
                               CKContainerWrapper<CKViewComponentAttributeValueMap> &&attrs = {}) noexcept;

  CKComponentViewConfiguration(CKComponentViewClass &&cls,
                               CKContainerWrapper<CKViewComponentAttributeValueMap> &&attrs,
                               CKComponentAccessibilityContext &&accessibilityCtx,
                               bool blockImplicitAnimations = false) noexcept;

  ~CKComponentViewConfiguration();
  bool operator==(const CKComponentViewConfiguration &other) const noexcept;

  const CKComponentViewClass &viewClass() const noexcept;
  std::shared_ptr<const CKViewComponentAttributeValueMap> attributes() const noexcept;
  const CKComponentAccessibilityContext &accessibilityContext() const noexcept;
  BOOL isDefaultConfiguration() const;
  bool blockImplicitAnimations() const noexcept;

private:
  struct Repr {
    CKComponentViewClass viewClass;
    std::shared_ptr<const CKViewComponentAttributeValueMap> attributes;
    CKComponentAccessibilityContext accessibilityContext;
    CK::Component::PersistentAttributeShape attributeShape;
    bool blockImplicitAnimations;
  };

  static std::shared_ptr<const Repr> singletonViewConfiguration();
  std::shared_ptr<const Repr> rep; // const is important for the singletonViewConfiguration optimization.

  friend class CK::Component::ViewReusePoolMap;    // uses attributeShape
};

namespace std {
  template<> struct hash<CKComponentViewConfiguration>
  {
    size_t operator()(const CKComponentViewConfiguration &cl) const noexcept;
  };
}
