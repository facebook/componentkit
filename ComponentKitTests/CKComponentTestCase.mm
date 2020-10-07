/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import "CKComponentTestCase.h"

#import <ComponentKit/CKComponentContextHelper.h>
#import <ComponentKit/CKComponentCreationValidation.h>

@implementation CKComponentTestCase
{
#if CK_ASSERTIONS_ENABLED
  CKComponentContextPreviousState _previousState;
#endif
}

- (void)setUp
{
  [super setUp];
#if CK_ASSERTIONS_ENABLED
  _previousState = CKComponentContextHelper::store(
    [CKComponentCreationValidationContext class],
    [[CKComponentCreationValidationContext alloc] initWithSource:CKComponentCreationValidationSourceBuild]
  );
#endif
}

- (void)tearDown
{
  [super tearDown];
#if CK_ASSERTIONS_ENABLED
  CKComponentContextHelper::restore(_previousState);
#endif
}

@end
