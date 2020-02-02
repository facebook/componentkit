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

#import <RenderCore/CKDimension.h>

/**
 A representation of a component's desired size relative to the size of its parent.

 CKComponentSize is much more expressive than CGSize. For example consider the following example:

   const CKComponentSize size = {
     .width = CKRelativeDimension::Percent(0.5),
     .maxWidth = 200,
     .minHeight = CKRelativeDimension::Percent(0.75),
   };

 This leads to a component size that is 50% of the width of its parent's width, up to a maximum width of 200 points. Its
 height will occupy at least 75% of its parent's height. Omitting any particular value of the component's size will lead
 to ComponentKit deferring the decision to layout. The final size of the component will be determined by the size of its
 parent and children.
 */
struct CKComponentSize {
  /**
   The width of the component relative to its parent's size.
   @see CKRelativeDimension
   */
  CKRelativeDimension width;
  /**
   The height of the component relative to its parent's size.
   @see CKRelativeDimension
   */
  CKRelativeDimension height;

  /**
   The minumum allowable width of the component relative to its parent's size.
   @see CKRelativeDimension
   */
  CKRelativeDimension minWidth;
  /**
   The minumum allowable height of the component relative to its parent's size.
   @see CKRelativeDimension
   */
  CKRelativeDimension minHeight;

  /**
   The maximum allowable width of the component relative to its parent's size.
   @see CKRelativeDimension
   */
  CKRelativeDimension maxWidth;
  /**
   The maximum allowable height of the component relative to its parent's size.
   @see CKRelativeDimension
   */
  CKRelativeDimension maxHeight;

  /**
   Creates a component size with the given size's width and height.
   @param size The size used to create the component size.
   @return A component size with the given size's width and height.
   */
  static CKComponentSize fromCGSize(CGSize size) noexcept;

  /**
   Resolves the component's size against the exact size of its parent.
   @param parentSize The exact size of the parent to be resolved against.
   @return A size range honoring the relative dimensions of the component size with respect to its parent's size.
   */
  CKSizeRange resolve(const CGSize &parentSize) const noexcept;

  bool operator==(const CKComponentSize &other) const noexcept;
  NSString *description() const noexcept;
};

namespace std {
  template <> struct hash<CKComponentSize> {
    size_t operator ()(const CKComponentSize &) noexcept;
  };
}

#endif
