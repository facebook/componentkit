/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDimension.h>

/**
 A struct specifying a component's size. Example:

   CKComponentSize size = {
     .width = Percent(0.5),
     .maxWidth = 200,
     .minHeight = Percent(0.75)
   };

   // <CKComponentSize: exact={50%, Auto}, min={Auto, 75%}, max={200pt, Auto}>
   size.description();

 */
struct CKComponentSize {
  CKRelativeDimension width;
  CKRelativeDimension height;

  CKRelativeDimension minWidth;
  CKRelativeDimension minHeight;

  CKRelativeDimension maxWidth;
  CKRelativeDimension maxHeight;

  static CKComponentSize fromCGSize(CGSize size);

  CKSizeRange resolve(const CGSize &parentSize) const;

  bool operator==(const CKComponentSize &other) const;
  NSString *description() const;
};

namespace std {
  template <> struct hash<CKComponentSize> {
    size_t operator ()(const CKComponentSize &);
  };
}