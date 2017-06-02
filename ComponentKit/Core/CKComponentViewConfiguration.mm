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

CKComponentViewClass::CKComponentViewClass() noexcept : factory(nil) {}

CKComponentViewClass::CKComponentViewClass(Class viewClass) noexcept :
identifier(class_getName(viewClass)),
factory(^{ return [[viewClass alloc] init]; }) {
  CKCAssert([viewClass isSubclassOfClass:[UIView class]], @"%@ is not a subclass of UIView", viewClass);
}

static CKComponentViewReuseBlock blockFromSEL(SEL sel) noexcept
{
  if (sel) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return ^(UIView *v){ [v performSelector:sel]; };
#pragma clang diagnostic pop
  }
  return nil;
}

CKComponentViewClass::CKComponentViewClass(Class viewClass, SEL enter, SEL leave) noexcept :
identifier(std::string(class_getName(viewClass)) + "-" + sel_getName(enter) + "-" + sel_getName(leave)),
factory(^{return [[viewClass alloc] init];}),
didEnterReusePool(blockFromSEL(enter)),
willLeaveReusePool(blockFromSEL(leave)) {}

CKComponentViewClass::CKComponentViewClass(UIView *(*fact)(void),
                                           void (^enter)(UIView *),
                                           void (^leave)(UIView *)) noexcept
: identifier(CKStringFromPointer((const void *)fact)), factory(^UIView*(void) {return fact();}), didEnterReusePool(enter), willLeaveReusePool(leave)
{
}

CKComponentViewClass::CKComponentViewClass(const std::string &i,
                                           UIView *(^fact)(void),
                                           void (^enter)(UIView *),
                                           void (^leave)(UIView *)) noexcept
: identifier(i), factory(fact), didEnterReusePool(enter), willLeaveReusePool(leave)
{
#if DEBUG
  CKCAssertNil(objc_getClass(i.c_str()), @"You may not use a class name as the identifier; it would conflict with "
               "the constructor variant that takes a viewClass.");
#endif
}

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
                                                           CKComponentAccessibilityContext &&accessibilityCtx) noexcept
{
  // Need to use attrs before we move it below.
  CKViewComponentAttributeValueMap attrsMap = attrs.take();
  CK::Component::PersistentAttributeShape attributeShape(attrsMap);
  rep.reset(new Repr({
    .viewClass = std::move(cls),
    .attributes = std::make_shared<CKViewComponentAttributeValueMap>(std::move(attrsMap)),
    .accessibilityContext = std::move(accessibilityCtx),
    .attributeShape = std::move(attributeShape)}));
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
        && other.rep->accessibilityContext == rep->accessibilityContext)) {
    return false;
  }

  const auto &otherAttributes = other.rep->attributes;
  if (otherAttributes == rep->attributes) {
    return true;
  } else if (otherAttributes->size() == rep->attributes->size()) {
    return std::find_if(rep->attributes->begin(),
                        rep->attributes->end(),
                        [&](std::pair<const CKComponentViewAttribute &, CK::ViewAttribute::BoxedValue> elem) {
                          const auto otherElem = otherAttributes->find(elem.first);
                          return otherElem == otherAttributes->end() || otherElem->second != elem.second;
                        }) == rep->attributes->end();
  } else {
    return false;
  }
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

UIView *CKComponentViewClass::createView() const
{
  return factory ? factory() : nil;
}

BOOL CKComponentViewClass::hasView() const
{
  return factory != nil;
}

size_t std::hash<CKComponentViewConfiguration>::operator()(const CKComponentViewConfiguration &cl) const noexcept
{
  NSUInteger subhashes[] = {
    std::hash<CKComponentViewClass>()(cl.viewClass()),
    std::hash<CKViewComponentAttributeValueMap>()(*cl.attributes()),
  };
  return CKIntegerArrayHash(subhashes, std::end(subhashes) - std::begin(subhashes));
};
