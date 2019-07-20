/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentViewConfiguration.h"

#import <objc/runtime.h>

#import <ComponentKit/CKAssert.h>

#import "CKInternalHelpers.h"


// It would be ideal to use std::unique_ptr here and give this class move semantics, but it already has value semantics
// and there are a few complicated flows.
std::shared_ptr<const CKComponentViewConfiguration::Repr> CKComponentViewConfiguration::singletonViewConfiguration()
{
  static std::shared_ptr<const CKComponentViewConfiguration::Repr> p = CKComponentViewConfiguration(CKComponentViewClass()).rep;
  return p;
}

CKComponentViewConfiguration::CKComponentViewConfiguration() noexcept
  :rep(singletonViewConfiguration()) {}

// Prefer overloaded constructors to default arguments to prevent code bloat; with default arguments
// the compiler must insert initialization of each default value inline at the callsite.
CKComponentViewConfiguration::CKComponentViewConfiguration(
    CKComponentViewClass &&cls,
    CKContainerWrapper<CKViewComponentAttributeValueMap> &&attrs) noexcept
: CKComponentViewConfiguration(std::move(cls), std::move(attrs), {}) {}

CKComponentViewConfiguration::CKComponentViewConfiguration(CKComponentViewClass &&cls,
                                                           CKContainerWrapper<CKViewComponentAttributeValueMap> &&attrs,
                                                           CKComponentAccessibilityContext &&accessibilityCtx,
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

// Constructors and destructors are defined out-of-line to prevent code bloat.
CKComponentViewConfiguration::~CKComponentViewConfiguration() {}

bool CKComponentViewConfiguration::operator==(const CKComponentViewConfiguration &other) const noexcept
{
  if (other.rep == rep) {
    return true;
  }
  if (!(other.rep->attributeShape == rep->attributeShape
        && other.rep->viewClass == rep->viewClass
        && other.rep->accessibilityContext == rep->accessibilityContext
        && other.rep->blockImplicitAnimations == rep->blockImplicitAnimations)) {
    return false;
  }

  const auto &otherAttributes = other.rep->attributes;
  if (otherAttributes == rep->attributes) {
    return true;
  } else if (otherAttributes->size() == rep->attributes->size()) {
    return std::find_if(rep->attributes->begin(),
                        rep->attributes->end(),
                        [&](std::pair<const CKComponentViewAttribute &, id> elem) {
                          const auto otherElem = otherAttributes->find(elem.first);
                          return otherElem == otherAttributes->end() || !CKObjectIsEqual(otherElem->second, elem.second);
                        }) == rep->attributes->end();
  } else {
    return false;
  }
}

BOOL CKComponentViewConfiguration::isDefaultConfiguration() const
{
  return rep == singletonViewConfiguration();
}

const CKComponentViewClass &CKComponentViewConfiguration::viewClass() const noexcept
{
  return rep->viewClass;
}

std::shared_ptr<const CKViewComponentAttributeValueMap> CKComponentViewConfiguration::attributes() const noexcept
{
  return rep->attributes;
}

const CKComponentAccessibilityContext &CKComponentViewConfiguration::accessibilityContext() const noexcept
{
  return rep->accessibilityContext;
}

bool CKComponentViewConfiguration::blockImplicitAnimations() const noexcept
{
  return rep->blockImplicitAnimations;
}

size_t std::hash<CKComponentViewConfiguration>::operator()(const CKComponentViewConfiguration &cl) const noexcept
{
  NSUInteger subhashes[] = {
    std::hash<CKComponentViewClass>()(cl.viewClass()),
    std::hash<CKViewComponentAttributeValueMap>()(*cl.attributes()),
    std::hash<bool>()(cl.blockImplicitAnimations()),
  };
  return CKIntegerArrayHash(subhashes, std::end(subhashes) - std::begin(subhashes));
};
