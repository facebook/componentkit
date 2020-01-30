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

#include <functional>

#import <Foundation/Foundation.h>

@protocol CKSystraceListener;

namespace CK {
namespace Analytics {

namespace BlockName {
static constexpr auto ComponentGeneratorWillGenerate = "COMPONENT_GENERATOR_ComponentGeneration";
static constexpr auto ComponentGeneratorWillApply = "COMPONENT_GENERATOR_ApplyGeneration";
static constexpr auto DataSourceWillStartModification = "CKDATASOURCE_StartModification";
static constexpr auto DataSourceWillApplyModification = "CKDATASOURCE_ApplyModification";
static constexpr auto ChangeSetApplicatorWillSwitchToApply = "CKDATASOURCE_CHANGESETAPPLICATOR_SwitchToApply";
static constexpr auto ChangeSetApplicatorWillVerifyChange = "CKDATASOURCE_CHANGESETAPPLICATOR_VerifyChange";
static constexpr auto ChangeSetApplicatorWillApplyChange = "CKDATASOURCE_CHANGESETAPPLICATOR_ApplyChange";
}

struct AsyncBlock {
  const char *const name;
  /**
   After switching to different queue this block will be invoked
   and will indicate the start of the trace
   */
  std::function<void(void)> didStartBlock;
};

/**
 The function to record the thread switch in traces. Should be called right before switching to different thread. Once the switch has occured, pass the
 returned object to CKSystraceScope constructor traces from different thread will automatically get connected

 @param blockName name of the trace block
 */
auto willStartAsyncBlock(const char *const blockName) -> AsyncBlock;

}
}

#endif
