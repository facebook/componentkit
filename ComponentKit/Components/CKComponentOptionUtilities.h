//
//  CKComponentOptionUtilities.h
//  ComponentKit
//
//  Created by Oliver Rickard on 2/4/17.
//
//

#import <Foundation/Foundation.h>

/**
 Allows us to define default values for optional primitive parameters while
 supporting aggregate initialization syntax in callsites.
 */
template<typename T, T const &def>
struct CKOptionalValue {
  CKOptionalValue() : _value(def) {};
  CKOptionalValue(const T &val) : _value(val) {};
  operator const T &() const { return _value; };
  const T &operator *(void) const { return _value; };
private:
  T _value;
};

template<typename T, T def>
struct CKOptionalPrimitiveValue {
  CKOptionalPrimitiveValue() : _value(def) {};
  CKOptionalPrimitiveValue(T val) : _value(val) {};
  operator T() const { return _value; };
  const T &operator *(void) const { return _value; };
private:
  T _value;
};
