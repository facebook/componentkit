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

@dynamicMemberLookup
@propertyWrapper
public struct Binding<Value> {
	private enum Store {
		case state(State<Value>)
		case closures(valueProvider: () -> Value, valueModifier: (Value) -> Void)
	}

	private let store: Store

	public init(state: State<Value>) {
		store = .state(state)
	}

	private init(closures: (valueProvider: () -> Value, valueModifier: (Value) -> ())) {
		store = .closures(valueProvider: closures.valueProvider, valueModifier: closures.valueModifier)
	}

	public var wrappedValue: Value {
		get {
			switch store {
			case .state(let state):
				return state.wrappedValue
			case .closures(let valueProvider, _):
				return valueProvider()
			}
		}
		nonmutating set {
			switch store {
			case .state(let state):
				state.wrappedValue = newValue
			case .closures(_, let valueModifier):
				valueModifier(newValue)
			}
		}
	}

	public var projectedValue: Binding<Value> {
		self
	}

	public subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> Binding<T> {
		switch store {
		case .state(let state):
			return Binding<T>(closures: ({ state.wrappedValue[keyPath: keyPath] }, { state.wrappedValue[keyPath: keyPath] = $0 }))
		case .closures(_, _):
			return Binding<T>(closures: ({ self.wrappedValue[keyPath: keyPath] }, { self.wrappedValue[keyPath: keyPath] = $0 }))
		}
	}
}


extension Binding : Equatable where Value : Equatable {
	static public func ==(lhs: Binding, rhs: Binding) -> Bool {
		switch (lhs.store, rhs.store) {
		case (.state(let lhsState), .state(let rhsState)):
			return lhsState == rhsState
		case (.closures(_, _), .closures(_, _)):
			return lhs.wrappedValue == rhs.wrappedValue
		default:
			return false
		}
	}
}

#endif
