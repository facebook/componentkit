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

struct CachedSetter {
  NSInvocation *invocation;
  NSUInteger argumentSize;
  const char *argumentType;

  CachedSetter(NSInvocation *inv, NSUInteger argSize, const char *argType) : invocation(inv), argumentSize(argSize), argumentType(argType) {}
};

static const CachedSetter &cachedSetterInvocation(id object, SEL setter)
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

static void performSetter(id object, SEL setter, id value)
{
  if ([value isKindOfClass:[NSValue class]]) {
    const CachedSetter &set = cachedSetterInvocation(object, setter);
    if (set.invocation) {
      if ([value isKindOfClass:[NSNumber class]]) {
        // We special case NSNumber because getting the correct byte width on both sides
        // is either hard (e.g. NSInteger), or impossible (e.g. CGFloat) on all architectures
        // simultaneously.
        // See https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
        // for more information on type encodings
        if (set.argumentType == nullptr || strlen(set.argumentType) != 1) {
          CKCAssert(NO, @"NSNumber: %@ cannot be used as an argument to a selector requiring '%s'", value, set.argumentType ?: "NULL");
          return;
        }
        NSNumber *numValue = (NSNumber *)value;
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
            CKCAssert(NO, @"NSNumber: %@ cannot be used as an argument to a selector requiring '%s'", value, set.argumentType);
            return;
        }
      } else {
        char buf[set.argumentSize];
        [value getValue:buf];
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
  [object performSelector:setter withObject:value];
#pragma clang diagnostic pop
}

CKComponentViewAttribute::CKComponentViewAttribute(SEL setter) :
identifier(sel_getName(setter)),
applicator(^(UIView *view, id value){
  performSetter(view, setter, value);
}) {}

// Explicit destructor to prevent inlining, reduce code size. See D1814602.
CKComponentViewAttribute::~CKComponentViewAttribute() {}

CKComponentViewAttribute CKComponentViewAttribute::LayerAttribute(SEL setter)
{
  return CKComponentViewAttribute(std::string("layer") + sel_getName(setter), ^(UIView *view, id value){
    performSetter(view.layer, setter, value);
  });
}
