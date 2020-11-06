/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKStatelessComponent.h"
#include <objc/runtime.h>
#import "CKStatelessComponentContext.h"

static const char metadataKey = ' ';

@implementation CKStatelessComponent

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view component:(CKComponent *)component metadata:(NSDictionary<NSString *, id> *)metadata identifier:(NSString *)identifier
{
  const auto c = [super newWithView:view component:component];

  if (c) {
    c->_identifier = [identifier copy];

    if (metadata != nil) {
      objc_setAssociatedObject(c, &metadataKey, metadata, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
  }

  return c;
}

+ (nullable instancetype)newWithView:(const CKComponentViewConfiguration &)view component:(CKComponent *_Nullable)component identifier:(NSString *)identifier
{
  return [self newWithView:view component:component metadata:nil identifier:identifier];
}

- (NSDictionary<NSString *, id> *)metadata
{
  return objc_getAssociatedObject(self, &metadataKey);
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@: %p> (CKStatelessComponent)", _identifier, self];
}

- (NSString *)className
{
  return _identifier;
}

@end

CKComponent *CKCreateStatelessComponent(NS_RELEASES_ARGUMENT CKComponent *component, NSDictionary<NSString *, id> *metadata, const char *debugIdentifier) NS_RETURNS_RETAINED
{
  if (component) {
#if CK_ASSERTIONS_ENABLED
    auto const shouldAllocateComponent = YES;
    CKCWarnWithCategory(component != nil, @(debugIdentifier), @"returns a nil component");
#else
    auto const shouldAllocateComponent = [CKComponentContext<CKStatelessComponentContext>::get() shouldAllocateComponent];
#endif
    if (shouldAllocateComponent || metadata != nil) {
      return
      [CKStatelessComponent
       newWithView:{}
       component:component
       metadata:metadata
       identifier:[NSString stringWithCString:debugIdentifier encoding:NSUTF8StringEncoding]];
    }
  }
  return component;
}

CKComponent *_Nullable CKCreateStatelessComponent(NS_RELEASES_ARGUMENT CKComponent *_Nullable component, const char *debugIdentifier)
{
  return CKCreateStatelessComponent(component, nil, debugIdentifier);
}
