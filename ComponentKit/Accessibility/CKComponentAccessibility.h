/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <ComponentKit/CKComponentAccessibilityContext.h>
#import <ComponentKit/CKComponentViewConfiguration.h>

namespace CK {
  namespace Component {
    namespace Accessibility {
      /**
       @return A modified configuration for which extra view component attributes have been added to handle accessibility.
       e.g: The following view configuration `{[UIView class], {{@selector(setBlah:), @"Blah"}}, {.accessibilityLabel = @"accessibilityLabel"}}`
       will become `{[UIView class], {{@selector(setBlah:), @"Blah"}, {@selector(setAccessibilityLabel), @"accessibilityLabel"}}, {.accessibilityLabel = @"accessibilityLabel"}}`
       */
      CKComponentViewConfiguration AccessibleViewConfiguration(const CKComponentViewConfiguration &viewConfiguration);
      BOOL IsAccessibilityEnabled();
      /**
       Force accessibility to be enabled or disabled.
       @param enabled A Boolean value that determines whether accessibility is forcibly enabled or disabled.
       @discussion Use for testing and tooling. Call ResetForceAccessibility() to reset to the default behavior.
       */
      void SetForceAccessibilityEnabled(BOOL enabled);
      /**
       Reset force accessibility to a default state (i.e. enabled only when VoiceOver is running)
       */
      void ResetForceAccessibility();
    }
  }
}

#endif
