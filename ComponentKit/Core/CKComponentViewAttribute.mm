/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentViewAttribute.h"

#import <objc/runtime.h>
#import <unordered_map>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKEqualityHashHelpers.h>
#import <ComponentKit/CKMacros.h>

/**
 * Helper macro for asserting that an @encode type is the same size as
 * a primitive type.
 */
#if DEBUG
#define CKCAssertSizeOfEquals(type, encodedType, ...) do {          \
  NSUInteger encodedTypeSize = 0;                                   \
  NSGetSizeAndAlignment((encodedType), &encodedTypeSize, nullptr);  \
  CKCAssert(sizeof(type) == encodedTypeSize, ##__VA_ARGS__);        \
} while (0)
#else
#define CKCAssertSizeOfEquals(type, encodedType, ...) do {} while(0)
#endif

struct SetterCacheKey {
  Class cls;
  SEL sel;

  bool operator==(const SetterCacheKey &other) const {
    return cls == other.cls && sel_isEqual(sel, other.sel);
  };
};

namespace std {
  template<>
  struct hash<SetterCacheKey>
  {
    std::size_t operator()(const SetterCacheKey &key) const
    {
      NSUInteger subhashes[] = { [key.cls hash], std::hash<void *>()((void *)key.sel) };
      return CKIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
    }
  };
}

CKComponentViewAttribute::CKComponentViewAttribute(SEL setter) noexcept :
identifier(sel_getName(setter)),
applicator([=](UIView *view, CK::ViewAttribute::BoxedValue value) {
  value.performSetter(view, setter);
}) {}

CKComponentViewAttribute::CKComponentViewAttribute(const std::string &ident, ApplicatorFunc app, ApplicatorFunc unapp, UpdaterFunc upd) :
identifier(ident),
applicator([=](id view, const CK::ViewAttribute::BoxedValue &value) {
  app(view, value);
}),
unapplicator(unapp ? ApplicatorFunc([=](id view, const CK::ViewAttribute::BoxedValue &value) {
  unapp(view, value);
}) : ApplicatorFunc(nullptr)),
updater(upd ? UpdaterFunc([=](id view, const CK::ViewAttribute::BoxedValue &oldValue, const CK::ViewAttribute::BoxedValue &newValue) {
  upd(view, oldValue, newValue);
}) : UpdaterFunc(nullptr)) {}

CKComponentViewAttribute::~CKComponentViewAttribute() = default;

CKComponentViewAttribute CKComponentViewAttribute::LayerAttribute(SEL setter) noexcept
{
  return {
    std::string("layer") + sel_getName(setter),
    [=](UIView *view, CK::ViewAttribute::BoxedValue value) {
      value.performSetter(view.layer, setter);
    }
  };
}

namespace CK {
  namespace ViewAttribute {

    struct CachedSetter {
      NSInvocation *invocation;
      NSUInteger argumentSize;
      const char *argumentType;

      CachedSetter(NSInvocation *inv, NSUInteger argSize, const char *argType) :
      invocation(inv),
      argumentSize(argSize),
      argumentType(argType) {}
    };

    static const CachedSetter &CachedSetterInvocation(id object, SEL setter)
    {
      CKCAssertMainThread();
      static auto *cachedInvocations = new std::unordered_map<SetterCacheKey, CachedSetter>();
      SetterCacheKey key = {[object class], setter};
      auto existingInvocation = cachedInvocations->find(key);
      if (existingInvocation != cachedInvocations->end()) {
        return existingInvocation->second;
      }

      NSMethodSignature *sig = [object methodSignatureForSelector:setter];
      // If the setter actually takes an NSValue id as the argument, we shouldn't unbox to the primitive type.
      const char *argumentType = [sig getArgumentTypeAtIndex:2];
      if (strcmp(argumentType, @encode(id)) != 0) {
        NSUInteger valueSize;
        NSGetSizeAndAlignment(argumentType, &valueSize, NULL);
        return cachedInvocations->emplace(key, CachedSetter([NSInvocation invocationWithMethodSignature:sig], valueSize, argumentType)).first->second;
      } else {
        return cachedInvocations->emplace(key, CachedSetter(nil, 0, nullptr)).first->second;
      }
    }

    ValueBase::ValueBase(const char *typeName) : _typeName(typeName) {}
    ValueBase::~ValueBase() = default;

    Value<id>::Value(const id &value) : ValueBase(typeid(Value<id>).name()), _value(value) {}
    Value<id>::~Value() = default;

    Value<id>::operator id() const
    {
      return _value;
    }

    size_t Value<id>::hash() const noexcept
    {
      return CK::hash<id>()(_value);
    }

    BOOL Value<id>::isEqualTo(const ValueBase &other) const
    {
      return this->typeName() == other.typeName() && CK::is_equal<id>()(_value, static_cast<const Value<id> &>(other)._value);
    }

    void CK::ViewAttribute::Value<id>::performSetter(id object, SEL setter) const
    {
      if ([_value isKindOfClass:[NSValue class]]) {
        const CachedSetter &set = CachedSetterInvocation(object, setter);
        if (set.invocation) {
          if ([_value isKindOfClass:[NSNumber class]]) {
            // We special case NSNumber because getting the correct byte width on both sides
            // is either hard (e.g. NSInteger), or impossible (e.g. CGFloat) on all architectures
            // simultaneously.
            // See https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
            // for more information on type encodings
            if (set.argumentType == nullptr || strlen(set.argumentType) != 1) {
              CKCAssert(NO, @"NSNumber: %@ cannot be used as an argument to a selector requiring '%s'", _value, set.argumentType ?: "NULL");
              return;
            }
            NSNumber *numValue = (NSNumber *)_value;
            switch (*set.argumentType) {
              case 'c': {
                CKCAssertSizeOfEquals(char, set.argumentType, @"");
                char charValue = [numValue charValue];
                [set.invocation setArgument:&charValue atIndex:2];
                break;
              }
              case 'i': {
                CKCAssertSizeOfEquals(int, set.argumentType, @"");
                int intValue = [numValue intValue];
                [set.invocation setArgument:&intValue atIndex:2];
                break;
              }
              case 's': {
                CKCAssertSizeOfEquals(short, set.argumentType, @"");
                short shortValue = [numValue shortValue];
                [set.invocation setArgument:&shortValue atIndex:2];
                break;
              }
              case 'l': {
                // This is inconsistent, from the docs: "l is treated as a 32-bit quantity on 64-bit programs."
                CKCAssertSizeOfEquals(int32_t, set.argumentType, @"");
                int32_t longValue = [numValue intValue];
                [set.invocation setArgument:&longValue atIndex:2];
                break;
              }
              case 'q': {
                CKCAssertSizeOfEquals(long long, set.argumentType, @"");
                long long longLongValue = [numValue longLongValue];
                [set.invocation setArgument:&longLongValue atIndex:2];
                break;
              }
              case 'C': {
                CKCAssertSizeOfEquals(unsigned char, set.argumentType, @"");
                unsigned char uCharValue = [numValue unsignedCharValue];
                [set.invocation setArgument:&uCharValue atIndex:2];
                break;
              }
              case 'I': {
                CKCAssertSizeOfEquals(unsigned int, set.argumentType, @"");
                unsigned int uIntValue = [numValue unsignedIntValue];
                [set.invocation setArgument:&uIntValue atIndex:2];
                break;
              }
              case 'S': {
                CKCAssertSizeOfEquals(unsigned short, set.argumentType, @"");
                unsigned short uShortValue = [numValue unsignedShortValue];
                [set.invocation setArgument:&uShortValue atIndex:2];
                break;
              }
              case 'L': {
                // This is also inconsistent, and undocumented
                CKCAssertSizeOfEquals(uint32_t, set.argumentType, @"");
                uint32_t uLongValue = [numValue unsignedIntValue];
                [set.invocation setArgument:&uLongValue atIndex:2];
                break;
              }
              case 'Q': {
                CKCAssertSizeOfEquals(unsigned long long, set.argumentType, @"");
                unsigned long long uLongLongValue = [numValue unsignedLongLongValue];
                [set.invocation setArgument:&uLongLongValue atIndex:2];
                break;
              }
              case 'f': {
                CKCAssertSizeOfEquals(float, set.argumentType, @"");
                float floatValue = [numValue floatValue];
                [set.invocation setArgument:&floatValue atIndex:2];
                break;
              }
              case 'd': {
                CKCAssertSizeOfEquals(double, set.argumentType, @"");
                double doubleValue = [numValue doubleValue];
                [set.invocation setArgument:&doubleValue atIndex:2];
                break;
              }
              case 'B': {
                CKCAssertSizeOfEquals(BOOL, set.argumentType, @"");
                BOOL boolValue = [numValue boolValue];
                [set.invocation setArgument:&boolValue atIndex:2];
                break;
              }
              default:
                // This should just be: 'v', '*', '@', '#', ':', '?', none of which should be boxed as NSNumber
                CKCAssert(NO, @"NSNumber: %@ cannot be used as an argument to a selector requiring '%s'", _value, set.argumentType);
                return;
            }
          } else {
            char buf[set.argumentSize];
            [_value getValue:buf];
            [set.invocation setArgument:buf atIndex:2];
          }
          [set.invocation setSelector:setter];
          [set.invocation invokeWithTarget:object];
          return;
        }
      }

      // ARC is worried that the selector might have a return value it doesn't know about, or be annotated with ns_consumed.
      // Neither is typically the case for setters, so ignore the warning.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [object performSelector:setter withObject:_value];
#pragma clang diagnostic pop
    }

    id nonIDObject = [NSObject new];
    
    template<> Value<bool>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<int8_t>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<uint8_t>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<int16_t>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<uint16_t>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<int32_t>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<uint32_t>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<int64_t>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<uint64_t>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<long>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<unsigned long>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<float>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<double>::operator id() const
    {
      return @(_value);
    }
    
    template<> Value<SEL>::operator id() const
    {
      return [NSValue valueWithPointer:_value];
    }
    
    template<> Value<CGRect>::operator id() const
    {
      return [NSValue valueWithCGRect:_value];
    }
    
    template<> Value<CGPoint>::operator id() const
    {
      return [NSValue valueWithCGPoint:_value];
    }
    
    template<> Value<CGSize>::operator id() const
    {
      return [NSValue valueWithCGSize:_value];
    }
    
    template<> Value<UIEdgeInsets>::operator id() const
    {
      return [NSValue valueWithUIEdgeInsets:_value];
    }
    
    template<> Value<CGAffineTransform>::operator id() const
    {
      return [NSValue valueWithCGAffineTransform:_value];
    }
    
    template<> Value<CATransform3D>::operator id() const
    {
      return [NSValue valueWithCATransform3D:_value];
    }

    BoxedValue::BoxedValue() : _value(std::make_shared<Value<id>>(nil)) {}
    BoxedValue::BoxedValue(id value) : _value(std::make_shared<Value<id>>(value)) {}
    BoxedValue::~BoxedValue() = default;

    BoxedValue::operator id() const
    {
      id const idObject = *_value;
      if (idObject != nonIDObject) {
        return idObject;
      }
      CKCFailAssert(@"value isn't an ID type object.");
      return nil;
    }

    size_t BoxedValue::hash() const noexcept
    {
      return _value->hash();
    }

    BOOL BoxedValue::operator==(const BoxedValue &other) const
    {
      return _value->isEqualTo(*other._value);
    }

    BOOL BoxedValue::operator!=(const BoxedValue &other) const
    {
      return !(*this == other);
    }

    void BoxedValue::performSetter(id object, SEL setter) const
    {
      _value->performSetter(object, setter);
    }

  }
}

template class std::unordered_map<CKComponentViewAttribute, CK::ViewAttribute::BoxedValue>;

template class CK::ViewAttribute::Value<id>;
template class CK::ViewAttribute::Value<bool>;
template class CK::ViewAttribute::Value<int8_t>;
template class CK::ViewAttribute::Value<uint8_t>;
template class CK::ViewAttribute::Value<int16_t>;
template class CK::ViewAttribute::Value<uint16_t>;
template class CK::ViewAttribute::Value<int32_t>;
template class CK::ViewAttribute::Value<uint32_t>;
template class CK::ViewAttribute::Value<int64_t>;
template class CK::ViewAttribute::Value<uint64_t>;
template class CK::ViewAttribute::Value<long>;
template class CK::ViewAttribute::Value<unsigned long>;
template class CK::ViewAttribute::Value<float>;
template class CK::ViewAttribute::Value<double>;
template class CK::ViewAttribute::Value<SEL>;
template class CK::ViewAttribute::Value<CGRect>;
template class CK::ViewAttribute::Value<CGPoint>;
template class CK::ViewAttribute::Value<CGSize>;
template class CK::ViewAttribute::Value<UIEdgeInsets>;
template class CK::ViewAttribute::Value<CGAffineTransform>;
template class CK::ViewAttribute::Value<CATransform3D>;

template CK::ViewAttribute::BoxedValue::BoxedValue(const bool &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const int8_t &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const uint8_t &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const int16_t &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const uint16_t &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const int32_t &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const uint32_t &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const int64_t &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const uint64_t &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const long &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const unsigned long &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const float &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const double &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const SEL &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const CGRect &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const CGPoint &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const CGSize &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const UIEdgeInsets &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const CGAffineTransform &);
template CK::ViewAttribute::BoxedValue::BoxedValue(const CATransform3D &);
