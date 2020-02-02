/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentViewClass.h"

#import <RenderCore/CKAssert.h>
#import <RenderCore/CKInternalHelpers.h>

std::string CKComponentViewClassIdentifier::description() const
{
  switch (this->identifierType) {
    case EMPTY_IDENTIFIER:
      return "";
    case CLASS_BASED_IDENTIFIER:
      return std::string(((const char *)this->ptr1)) + "-" + (const char *)this->ptr2 + "-" + (const char *)this->ptr3;
    case FUNCTION_BASED_IDENTIFIER:
      return CKStringFromPointer((const void *)this->ptr1);
  }
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

static CKComponentViewFactoryBlock viewFactoryFromViewClass(Class viewClass) noexcept
{
  CKCAssert([viewClass isSubclassOfClass:[UIView class]], @"%@ is not a subclass of UIView", viewClass);
  // Passing a nil `viewClass` is unexpected. We should return a nil view factory and treat this as a viewless component.
  // Otherwise nil will be returned by view factory and it will crash.
  if (viewClass) {
    return ^{ return [[viewClass alloc] init]; };
  } else {
    return nil;
  }
}

CKComponentViewClass::CKComponentViewClass() noexcept : factory(nil)
{
}

CKComponentViewClass::CKComponentViewClass(Class viewClass) noexcept :
factory(viewFactoryFromViewClass(viewClass))
{
  identifier = { viewClass };
}

CKComponentViewClass::CKComponentViewClass(Class viewClass, SEL enter, SEL leave) noexcept :
factory(viewFactoryFromViewClass(viewClass)),
didEnterReusePool(blockFromSEL(enter)),
willLeaveReusePool(blockFromSEL(leave))
{
  identifier = { viewClass, enter, leave };
}

CKComponentViewClass::CKComponentViewClass(CKComponentViewFactoryFunc fact,
                                           void (^enter)(UIView *),
                                           void (^leave)(UIView *)) noexcept
: factory(^UIView*(void) {return fact();}), didEnterReusePool(enter), willLeaveReusePool(leave)
{
  identifier = { fact };
}

UIView *CKComponentViewClass::createView() const
{
  return factory ? factory() : nil;
}

BOOL CKComponentViewClass::hasView() const
{
  return factory != nil;
}
