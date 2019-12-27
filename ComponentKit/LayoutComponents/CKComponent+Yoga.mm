/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponent+Yoga.h"

#import "CKComponentInternal.h"

YGConfigRef ckYogaDefaultConfig()
{
  static YGConfigRef defaultConfig;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultConfig = YGConfigNew();
    YGConfigSetPointScaleFactor(defaultConfig, [UIScreen mainScreen].scale);
  });
  return defaultConfig;
}

CK_LINKABLE(CKComponent_Yoga)
@implementation CKComponent (Yoga)

- (BOOL)isYogaBasedLayout
{
  return NO;
}

- (CKComponentSize)nodeSize
{
  return [self size];
}

- (YGNodeRef)ygNode:(CKSizeRange)constrainedSize
{
  return YGNodeNewWithConfig(ckYogaDefaultConfig());
}

- (CKComponentLayout)layoutFromYgNode:(YGNodeRef)layoutNode thatFits:(CKSizeRange)constrainedSize
{
  return {};
}

- (BOOL)usesCustomBaseline
{
  return NO;
}

@end

CK_LINKABLE(CKCompositeComponent_Yoga)
@implementation CKCompositeComponent (Yoga)

- (BOOL)isYogaBasedLayout
{
  return self.child.isYogaBasedLayout;
}

- (CKComponentSize)nodeSize
{
  return [self.child nodeSize];
}

- (YGNodeRef)ygNode:(CKSizeRange)constrainedSize
{
  return [self.child ygNode:constrainedSize];
}

- (CKComponentLayout)layoutFromYgNode:(YGNodeRef)layoutNode thatFits:(CKSizeRange)constrainedSize
{
  const CKComponentLayout l = [self.child layoutFromYgNode:layoutNode thatFits:constrainedSize];
  return {self, l.size, {{{0,0}, l}}};
}

@end
