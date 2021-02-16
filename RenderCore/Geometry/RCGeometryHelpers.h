/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#import <UIKit/UIKit.h>

inline CGPoint operator+(const CGPoint &p1, const CGPoint &p2)
{
  return { p1.x + p2.x, p1.y + p2.y };
}

inline CGPoint operator-(const CGPoint &p1, const CGPoint &p2)
{
  return { p1.x - p2.x, p1.y - p2.y };
}

inline CGSize operator+(const CGSize &s1, const CGSize &s2)
{
  return { s1.width + s2.width, s1.height + s2.height };
}

inline CGSize operator-(const CGSize &s1, const CGSize &s2)
{
  return { s1.width - s2.width, s1.height - s2.height };
}

inline UIEdgeInsets operator+(const UIEdgeInsets &e1, const UIEdgeInsets &e2)
{
  return { e1.top + e2.top, e1.left + e2.left, e1.bottom + e2.bottom, e1.right + e2.right };
}

inline UIEdgeInsets operator-(const UIEdgeInsets &e1, const UIEdgeInsets &e2)
{
  return { e1.top - e2.top, e1.left - e2.left, e1.bottom - e2.bottom, e1.right - e2.right };
}

inline UIEdgeInsets operator*(const UIEdgeInsets &e1, const UIEdgeInsets &e2)
{
  return { e1.top * e2.top, e1.left * e2.left, e1.bottom * e2.bottom, e1.right * e2.right };
}

inline UIEdgeInsets operator-(const UIEdgeInsets &e)
{
  return { -e.top, -e.left, -e.bottom, -e.right };
}

#endif
