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

private func makeChild() -> FlexboxComponent.Child {
  fatalError()
}

private func buildComponents(@FlexboxChildrenBuilder children: () -> [FlexboxComponent.Child]) { }

private struct MyView: CKSwift.View, ViewConfigurationRepresentable {
  let viewConfiguration = ViewConfiguration(viewClass: UIView.self)
}

class FlexboxChildrenBuilderTests : XCTestCase {

  func testConvertSingleComponentToChild() {
    buildComponents {
      Component()
    }
  }

  func testConvertSingleViewToChild() {
    buildComponents {
      ComponentView<UIView>()
    }
  }

  func testSingleChildWithSingleComponent() {
    buildComponents {
      makeChild()
    }
  }

  func testMulti() {
    buildComponents {
      ComponentView<UIView>()
      Component()
      makeChild()
      ComponentView<UIView>()
      Component()
      makeChild()
    }
  }

  func testConditions() {
    let condition = Int.random(in: 0..<100) == 0
    buildComponents {
      if condition {
        Component()
      }

      if condition {
        ComponentView<UIView>()
      }

      if condition {
        makeChild()
      }

      if condition {
        Component()
      } else {
        ComponentView<UIView>()
      }

      if condition {
        ComponentView<UIView>()
      } else {
        Component()
      }

      if condition {
        ComponentView<UIView>()
      } else {
        Component()
      }

      if condition {
        makeChild()
      } else {
        makeChild()
      }
    }
  }

  func testSwitch() {
    buildComponents {
      switch Int.random(in: 0..<3) {
      case 0:
        Component()
      case 1:
        makeChild()
      default:
        ComponentView<UIView>()
      }
    }
  }

  func testInputArray() {
    let children: [FlexboxComponent.Child] = []
    let children2: Set<FlexboxComponent.Child> = []
    let childrenComponents: [Component] = []
    let childrenViews: [MyView] = []
    buildComponents {
      children
      children2
      childrenComponents
      childrenViews
    }
  }

  func testLimitedAvailability() {
    buildComponents {
      if #available(macOS 9, *) {
        ComponentView<UIView>()
      }

      if #available(macOS 10.16, *) {
        ComponentView<UIView>()
      }

      if #available(macOS 9000, *) {
        ComponentView<UIView>()
      }
    }
  }

  func testDo() {
    buildComponents {
      do {
        Component()
        ComponentView<UIView>()
        makeChild()
      }
    }
  }
}
