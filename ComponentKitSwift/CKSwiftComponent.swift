//
//  File.swift
//  ComponentKit
//
//  Created by Oliver Rickard on 12/11/16.
//
//

import Foundation

struct ViewConfiguration {
  var viewClass: UIView.Type?;
  var viewAttributes: Dictionary<Selector, AnyObject>?;

  init() {

  }
}

struct NoState {}

class Scope<StateType> {
  init(componentClass: Component.Type, identifier: AnyObject? = nil, initialStateCreator:(() -> AnyObject)? = nil) {
    scopeRef = CKComponentScopeRefCreate(componentClass, identifier, initialStateCreator);
  }

  deinit {
    assert(destroyedRef, "You must close a scope before it is deallocated");
  }

  func close() {
    if !destroyedRef {
      CKComponentScopeRefDestroy(scopeRef);
    }
  }

  var scopeRef: COpaquePointer;
  var destroyedRef: Bool = false;

  func state() -> StateType {
    assert(!destroyedRef, "Attempting to access state on closed scope.");
    return CKComponentScopeRefGetState(scopeRef) as! StateType;
  }
}

class Component: CKComponent {
  init(view: ViewConfiguration) {
    let mapRef = CKViewComponentAttributeValueMapRefCreate();
    if view.viewAttributes != nil {
      for (sel, value) in view.viewAttributes! {
        CKViewComponentAttributeValueMapRefAddAttribute(mapRef, sel, value);
      }
    }
    let viewRef = CKComponentViewConfigurationRefCreate(view.viewClass, mapRef);
    CKViewComponentAttributeValueMapRefDestroy(mapRef);
    super.init(viewRef: viewRef);
    CKComponentViewConfigurationRefDestroy(viewRef);
  }
}

class Controller: CKComponentController {

}

class TestComponent: Component {
  init() {
    var s: Scope<String> = Scope(componentClass: TestComponent.self); defer { s.close() }

    let string = s.state();

    print(string);

    super.init(view: ViewConfiguration());
  }
}

class TestComponentController: Controller {

}
