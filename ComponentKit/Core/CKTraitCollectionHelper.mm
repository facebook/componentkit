/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import "CKTraitCollectionHelper.h"

void CKPerformWithCurrentTraitCollection(UITraitCollection *traitCollection, void (NS_NOESCAPE ^action)(void))
{
  if (!action) {
    return;
  }
  if (traitCollection) {
    if (@available(iOS 13.0, tvOS 13.0, *)) {
      [traitCollection performAsCurrentTraitCollection:action];
    } else {
      action();
    }
  } else {
    action();
  }
}
