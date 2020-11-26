/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

import XCTest
import CKSwift

class ActionTests : XCTestCase {
  var param: Int?

  private func actionHandler(param: Int) {
    self.param = param
  }

  override func setUp() {
    super.setUp()
    param = nil
  }

  func test_TargetHandlerAction_Works() {
    let action = ActionWith<Int>(target: self, handler: type(of: self).actionHandler)

    action.invoke(42)

    XCTAssertEqual(param, 42)
  }

  func test_TargetHandlerAction_DoesNotRetain() {
    class Handler { func doNothing() { }}

    weak var weakHandler: Handler?
    var action: Action?

    autoreleasepool {
      let handler = Handler()
      weakHandler = handler
      action = Action(target: handler, handler: type(of: handler).doNothing)
      XCTAssertNotNil(weakHandler)
      XCTAssertNotNil(action)
    }
    XCTAssertNil(weakHandler)
  }
}
