/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <string>
#import <unordered_map>

#import <UIKit/UIKit.h>

/**
 View attributes usually correspond to properties (like background color or alpha) but can represent arbitrarily complex
 operations on the view.
 */
struct CKComponentViewAttribute {
  /**
   The most common way to specify an attribute is by using a SEL corresponding to a setter, e.g. @selector(setColor:).
   This single-argument constructor allows implicit conversions, so you can pass a SEL as an attribute without actually
   typing CKComponentViewAttribute().
   */
  CKComponentViewAttribute(SEL setter);
  /**
   Constructor for complex attributes.

   @param ident A unique identifier for the attribute, used by the infrastructure to distinguish them internally.
   @param app   An "applicator" for the attribute. If the value of an attribute differs from the previously applied
                value for a recycled view (or if the view is newly created), the applicator is called with the view
                and the attribute's value.
   @param unapp An optional "un-applicator". This is called when a view that had an applicator is being reused. This
                is where you do teardown that requires more than just the next applicator smashing over an
                old value. Note: the unapplicator will not be called before a view is released.
   @param upd   An optional "updater". This may be used as an advanced performance optimization if you can reconfigure
                the view more efficiently if you know the previous value.

   This diagram summarizes the behaviors of unapplicator and updater in combination:

   |--------|----------|-----------------------------------------------------------------------------------------------|
   | unapp? | updater? | Behavior                                                                                      |
   |--------|----------|-----------------------------------------------------------------------------------------------|
   | no     | no       | Views cannot be recycled to show components that do not have the attribute.                   |
   |        |          | In almost all cases, this is the best option.                                                 |
   |--------|----------|-----------------------------------------------------------------------------------------------|
   | yes    | no       | Unapplic. is called if the view is being recycled to show a component without the attribute,  |
   |        |          | or if the value of the attribute has changed (followed by applicator with new value).         |
   |--------|----------|-----------------------------------------------------------------------------------------------|
   | no     | yes      | Views cannot be recycled to show components that do not have the attribute.                   |
   |        |          | Applicator is called first time; subsequently, updater is called if the value changes.        |
   |--------|----------|-----------------------------------------------------------------------------------------------|
   | yes    | yes      | Unapplic. is called if the view is being recycled to show a component without the attribute.  |
   |        |          | Updater is called if the attribute was previously applied and the value changes.              |
   |--------|----------|-----------------------------------------------------------------------------------------------|
   */
  CKComponentViewAttribute(const std::string &ident,
                           void (^app)(id view, id value),
                           void (^unapp)(id view, id value) = nil,
                           void (^upd)(id view, id oldValue, id newValue) = nil) :
  identifier(ident),
  applicator(app),
  unapplicator(unapp),
  updater(upd) {};

  ~CKComponentViewAttribute();

  /**
   Creates an attribute that invokes the given setter on the view's layer (rather than the view itself). Useful for
   easy access to layer properties, e.g. @selector(setBorderColor:), @selector(setAnchorPoint:), and so on.
   */
  static CKComponentViewAttribute LayerAttribute(SEL setter);

  std::string identifier;
  void (^applicator)(id view, id value);
  void (^unapplicator)(id view, id value);
  void (^updater)(id view, id oldValue, id newValue);

  bool operator==(const CKComponentViewAttribute &attr) const { return identifier == attr.identifier; };
};

namespace std {
  template<> struct hash<CKComponentViewAttribute>
  {
    size_t operator()(const CKComponentViewAttribute &attr) const
    {
      return hash<std::string>()(attr.identifier);
    }
  };
}

typedef std::unordered_map<CKComponentViewAttribute, id> CKViewComponentAttributeValueMap;

/**
 This typedef is provided for convenience for helper functions that return both an attribute and a value, ready-made
 for dropping into the initialization list for attributes.
 e.g: It is currently used in CKComponentViewConfiguration, CKComponentViewConfiguration.attribute is of type
 std::unordered_map<CKComponentViewAttribute, id> (CKViewComponentAttributeValueMap). Its aggregate initialization
 constructor takes a list of std::pair<CKComponentViewAttribute, id>.
 */
typedef CKViewComponentAttributeValueMap::value_type CKComponentViewAttributeValue;
