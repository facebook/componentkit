/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

namespace CK {
  namespace Component {
    namespace Accessibility {

      /**
       Force enable or disable accessibility.
       @param enabled A Boolean value that determines whether accessibility is enabled.
       @discussion Used for testing. All current unit tests at the date of adding this where written under the
       assumption that accessibility is not enabled. When setting to YES remember to set to NO on teardown.
       */
      void SetForceAccessibilityEnabled(BOOL enabled);
    }
  }
}
