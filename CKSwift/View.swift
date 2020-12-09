/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

import Foundation
import ComponentKit

#if swift(>=5.3)

// MARK: ComponentInflatable

/// Can be inflated to a `Component` given a `SwiftComponentModel`.
/// Anything that is `ComponentInflatable` can be added to a CKSwift view hierarchy.
public protocol ComponentInflatable {
  func inflateComponent(with model: SwiftComponentModel?) -> Component
}

// MARK: View

public protocol View : ComponentInflatable {
  associatedtype Body
  @ComponentBuilder var body: Body { get }
}

extension View where Self.Body == Never {
  public var body: Never {
    // Leaf views don't return
    fatalError("Attempting to call .body on a leaf view")
  }
}

public protocol ViewIdentifiable : ScopeHandleProvider {
  associatedtype ID: Hashable
  var id: ID { get }
}

// MARK: Non-leaf component

extension View where Self.Body == Component {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic

    let hasScopeHandle = linkPropertyWrappersWithScopeHandle(
      forceRequireNode: model?.isEmpty == false)

    if hasScopeHandle == false {
      // If the current view doesn't require a scope handle and there is no view configuration
      // simply inflate the body to reduce the number of components generated. aka Stateless.
      return body.inflateComponent(with: model)
    }

    defer {
      if hasScopeHandle {
        CKSwiftPopClass()
      }
    }

    return SwiftComponent(
      self,
      body: body,
      model: model
    )
  }
}

extension View where Self: ViewIdentifiable, Self.Body == Component {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    linkPropertyWrappersWithScopeHandle()

    defer {
      CKSwiftPopClass()
    }

    return SwiftComponent(
      self,
      body: body,
      model: model
    )
  }
}

extension View where Self: ViewIdentifiable & Equatable, Self.Body == Component {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    linkPropertyWrappersWithScopeHandle()

    defer {
      CKSwiftPopClass()
    }

    return SwiftReusableComponent(
      self,
      body: CKShouldCreateShellComponent() ? nil : body,
      model: model
    )
  }
}


extension View where Self: ViewConfigurationRepresentable, Self.Body == Component {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    let hasScopeHandle = linkPropertyWrappersWithScopeHandle(
      forceRequireNode: model?.isEmpty == false
    )

    defer {
      if hasScopeHandle {
        CKSwiftPopClass()
      }
    }

    return SwiftComponent(
      self,
      viewConfiguration: viewConfiguration,
      model: model
    )
  }
}

extension View where Self: ViewIdentifiable & ViewConfigurationRepresentable, Self.Body == Component {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    linkPropertyWrappersWithScopeHandle()

    defer {
      CKSwiftPopClass()
    }

    return SwiftComponent(
      self,
      body: CKShouldCreateShellComponent() ? nil : body,
      viewConfiguration: viewConfiguration,
      model: model
    )
  }
}

extension View where Self: ViewIdentifiable & ViewConfigurationRepresentable & Equatable, Self.Body == Component {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    linkPropertyWrappersWithScopeHandle()

    defer {
      CKSwiftPopClass()
    }

    return SwiftReusableComponent(
      self,
      body: CKShouldCreateShellComponent() ? nil : body,
      viewConfiguration: viewConfiguration,
      model: model
    )
  }
}

// MARK: Leaf component

extension View where Self: ViewConfigurationRepresentable, Self.Body == Never {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    let hasScopeHandle = linkPropertyWrappersWithScopeHandle(
      forceRequireNode: model?.isEmpty == false)

    defer {
      if hasScopeHandle {
        CKSwiftPopClass()
      }
    }

    return SwiftComponent(
      self,
      viewConfiguration: viewConfiguration,
      model: model
    )
  }
}

extension View where Self: ViewConfigurationRepresentable & ViewIdentifiable, Self.Body == Never {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    linkPropertyWrappersWithScopeHandle()

    defer {
      CKSwiftPopClass()
    }

    return SwiftComponent(
      self,
      viewConfiguration: viewConfiguration,
      model: model
    )
  }
}

extension View where Self: ViewConfigurationRepresentable & ViewIdentifiable & Equatable, Self.Body == Never {
  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    // TODO: Reuse logic
    linkPropertyWrappersWithScopeHandle()

    defer {
      CKSwiftPopClass()
    }

    return SwiftReusableLeafComponent(
      self,
      viewConfiguration: viewConfiguration,
      model: model
    )
  }
}

// MARK: Link

private extension View {

  private var linkableItems: [ScopeHandleLinkable] {
    Mirror(reflecting: self)
      .children
      .compactMap {
        $0.value as? ScopeHandleLinkable
      }
  }

  private func link(linkableItems: [ScopeHandleLinkable], id: Any?) {
    let scopeHandle = CKSwiftCreateScopeHandle(SwiftComponent<Self>.self, id)
    linkableItems
      .enumerated()
      .forEach { index, item in
        item.link(with: scopeHandle, at: index)
      }
  }

  func linkPropertyWrappersWithScopeHandle(forceRequireNode: Bool) -> Bool {
    let linkableItems = self.linkableItems
    guard linkableItems.isEmpty == false || forceRequireNode || self is ScopeHandleProvider else {
      return false
    }

    link(linkableItems: linkableItems, id: nil)
    return true
  }
}

private extension View where Self: ViewIdentifiable {
  func linkPropertyWrappersWithScopeHandle() {
    link(linkableItems: linkableItems, id: id)
  }
}

#endif
