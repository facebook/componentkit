/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import "CKViewConfiguration.h"

CKViewConfiguration::CKViewConfiguration() noexcept :
rep(singletonViewConfiguration()) {}

CKViewConfiguration::CKViewConfiguration(CKComponentViewClass &&cls) noexcept :
CKViewConfiguration(std::move(cls), {}) {}

CKViewConfiguration::CKViewConfiguration(const CKViewConfiguration&) noexcept = default;

// Prefer overloaded constructors to default arguments to prevent code bloat; with default arguments
// the compiler must insert initialization of each default value inline at the callsite.
CKViewConfiguration::CKViewConfiguration(CKComponentViewClass &&cls,
                  RCContainerWrapper<CKViewComponentAttributeValueMap> &&attrs) noexcept :
CKViewConfiguration(std::move(cls), std::move(attrs), {}) {}

CKViewConfiguration::CKViewConfiguration(CKComponentViewClass &&cls,
                  RCContainerWrapper<CKViewComponentAttributeValueMap> &&attrs,
                  CKAccessibilityContext &&accessibilityCtx,
                  bool blockImplicitAnimations) noexcept
{
  // Need to use attrs before we move it below.
  CKViewComponentAttributeValueMap attrsMap = attrs.take();
  CK::Component::PersistentAttributeShape attributeShape(attrsMap);
  rep.reset(new Repr({
    .viewClass = std::move(cls),
    .attributes = std::make_shared<CKViewComponentAttributeValueMap>(std::move(attrsMap)),
    .accessibilityContext = std::move(accessibilityCtx),
    .attributeShape = std::move(attributeShape),
    .blockImplicitAnimations = blockImplicitAnimations
  }));
}

CKViewConfiguration CKViewConfiguration::forceViewClassIfNone(CKComponentViewClass &&cls) const noexcept
{
  if (rep->viewClass.hasView()) {
    return *this;
  } else if (isDefaultConfiguration()) {
    return CKViewConfiguration{std::move(cls)};
  } else {
    auto attributes = *rep->attributes;
    auto accessibilityContext = rep->accessibilityContext;
    return CKViewConfiguration{
      std::move(cls),
      std::move(attributes),
      std::move(accessibilityContext),
      rep->blockImplicitAnimations
    };
  }
}

CKViewConfiguration::~CKViewConfiguration() {}

const CKComponentViewClass &CKViewConfiguration::viewClass() const noexcept
{
  return rep->viewClass;
}

std::shared_ptr<const CKViewComponentAttributeValueMap> CKViewConfiguration::attributes() const noexcept
{
  return rep->attributes;
}

const CKAccessibilityContext &CKViewConfiguration::accessibilityContext() const noexcept
{
  return rep->accessibilityContext;
}

BOOL CKViewConfiguration::isDefaultConfiguration() const
{
  return rep == singletonViewConfiguration();
}

bool CKViewConfiguration::blockImplicitAnimations() const noexcept
{
  return rep->blockImplicitAnimations;
}

const CK::Component::PersistentAttributeShape &CKViewConfiguration::attributeShape() const noexcept
{
  return rep->attributeShape;
}
