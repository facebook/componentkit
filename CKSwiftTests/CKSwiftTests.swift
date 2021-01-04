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

class CKSwiftTests : XCTestCase {
  func test_InitialisingDimension() {
    XCTAssertEqual(Dimension.points(20).description, "20pt")
    XCTAssertEqual(Dimension.percent(0.5).description, "50%")
  }

  func test_WhenInitialisedWithFloatLiteral_InitialisesDimensionWithPoints() {
    let d: CKSwift.Dimension = 42.0
    XCTAssertEqual(d.description, "42pt")
  }

  func test_WhenInitialisedWithIntLiteral_InitialisesDimensionWithPoints() {
    let d: CKSwift.Dimension = 42
    XCTAssertEqual(d.description, "42pt")
  }

  func test_InitialisingComponentSizeWithCGSize() {
    let expected = "<CKComponentSize: exact={100pt, 200pt}, min={Auto, Auto}, max={Auto, Auto}>"
    XCTAssertEqual(ComponentSize(size: CGSize(width: 100, height: 200)).description, expected)
  }

  func test_InitialisingComponentSizeWithDimensions() {
    let expected = "<CKComponentSize: exact={200pt, 300pt}, min={100pt, 50pt}, max={400pt, 600pt}>"
    XCTAssertEqual(ComponentSize(width: 200, height: 300, minWidth: 100, minHeight: 50, maxWidth: 400, maxHeight: 600).description, expected)
  }

  func test_WhenDimensionIsOmitted_ThisDimensionInitialisedToAuto() {
    let expected = "<CKComponentSize: exact={50%, Auto}, min={Auto, Auto}, max={Auto, Auto}>"
    XCTAssertEqual(ComponentSize(width: .percent(0.5)).description, expected)
  }

  func test_InitialisingSizeRange() {
    let sizeRange = SizeRange(minSize: CGSize(width: 100, height: 200), maxSize: CGSize(width: 200, height: 300))

    let expected = "<CKSizeRange: min={100, 200}, max={200, 300}>"
    XCTAssertEqual(sizeRange.description, expected)
  }

  func test_WhenSizingHostingView_InvokesSizeRangeProvider() {
    var sizeRangeProviderWasCalledWithExpectedSize = false
    let expectedSize = CGSize(width: 320, height: 480)
    let hv = ComponentHostingView<NSNumber, NSObject>(
      componentProvider: { _, _ in return Component() },
      sizeRangeProviderBlock: { size in
        sizeRangeProviderWasCalledWithExpectedSize = (size == expectedSize)
        return SizeRange(minSize: size, maxSize: size)
    })
    hv.updateModel(2, mode: .asynchronous)
    hv.updateContext(nil, mode: .synchronous)

    let _ = hv.sizeThatFits(expectedSize)

    XCTAssert(sizeRangeProviderWasCalledWithExpectedSize)
  }
}
