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

#import <ComponentKit/ComponentMountContext.h>
#import <ComponentKit/ComponentViewManager.h>
#import <ComponentKit/ComponentViewReuseUtilities.h>
#import <ComponentKit/CKComponentAccessibility.h>
#import <ComponentKit/CKComponentViewAttribute.h>

class CKComponentDebugConfiguration;

typedef void (^CKComponentViewReuseBlock)(UIView *);

struct CKComponentViewClass {

  /**
   The no-argument default constructor, which specifies that the component should not have a corresponding view.
   */
  CKComponentViewClass();

  /**
   Specifies that the component should have a view of the given class. The class will be instantiated with UIView's
   designated initializer -initWithFrame:.
   */
  CKComponentViewClass(Class viewClass);

  /**
   A variant that allows you to specify two selectors that are sent as a view is hidden/unhidden for future reuse.
   Note that a view can be reused but not hidden so never enters the pool (in which case these selectors won't be sent).
   @param didEnterReusePoolMessage Sent to the view just after it has been hidden for future reuse.
   @param willLeaveReusePool Sent to the view just before it is revealed after being reused.
   */
  CKComponentViewClass(Class viewClass, SEL didEnterReusePoolMessage, SEL willLeaveReusePoolMessage);

  /**
   Specifies a view class that cannot be instantiated with -initWithFrame:.
   Allows you to specify two blocks that are invoked as a view is hidden/unhidden for future reuse.
   Note that a view can be reused but not hidden so never enters the pool (in which case these blocks won't be invoked).
   @param factory A pointer to a function that returns a new instance of a view.
   @param didEnterReusePool Executed after a view has been hidden for future reuse.
   @param willLeaveReusePool Executed just before a view is revealed after being reused.
   */
  CKComponentViewClass(UIView *(*factory)(void),
                       CKComponentViewReuseBlock didEnterReusePool = nil,
                       CKComponentViewReuseBlock willLeaveReusePool = nil);

  /** Invoked by the infrastructure to create a new instance of the view. You should not call this directly. */
  UIView *createView() const;

  /** Invoked by the infrastructure to determine if this will create a view or not. */
  BOOL hasView() const;

  bool operator==(const CKComponentViewClass &other) const { return other.identifier == identifier; }
  bool operator!=(const CKComponentViewClass &other) const { return other.identifier != identifier; }

  const std::string &getIdentifier() const { return identifier; }

private:
  CKComponentViewClass(const std::string &ident,
                       UIView *(^factory)(void),
                       CKComponentViewReuseBlock didEnterReusePool = nil,
                       CKComponentViewReuseBlock willLeaveReusePool = nil);
  std::string identifier;
  UIView *(^factory)(void);
  CKComponentViewReuseBlock didEnterReusePool;
  CKComponentViewReuseBlock willLeaveReusePool;
  friend class CK::Component::ViewReuseUtilities;
};

namespace std {
  template<> struct hash<CKComponentViewClass>
  {
    size_t operator()(const CKComponentViewClass &cl) const
    {
      return hash<std::string>()(cl.getIdentifier());
    }
  };
}

/**
 A CKComponentViewConfiguration specifies the class of a view and the attributes that should be applied to it.
 Initialize a configuration with brace syntax, for example:

 {[UIView class]}
 {[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}, {@selector(setAlpha:), @0.5}}}
 */
struct CKComponentViewConfiguration {

  CKComponentViewConfiguration();

  CKComponentViewConfiguration(CKComponentViewClass &&cls,
                               CKViewComponentAttributeValueMap &&attrs = {});

  CKComponentViewConfiguration(CKComponentViewClass &&cls,
                               CKViewComponentAttributeValueMap &&attrs,
                               CKComponentAccessibilityContext &&accessibilityCtx);

  ~CKComponentViewConfiguration();
  bool operator==(const CKComponentViewConfiguration &other) const;

  const CKComponentViewClass &viewClass() const;
  std::shared_ptr<const CKViewComponentAttributeValueMap> attributes() const;
  const CKComponentAccessibilityContext &accessibilityContext() const;

private:
  struct Repr {
    CKComponentViewClass viewClass;
    std::shared_ptr<const CKViewComponentAttributeValueMap> attributes;
    CKComponentAccessibilityContext accessibilityContext;
    CK::Component::PersistentAttributeShape attributeShape;
  };

  static std::shared_ptr<const Repr> singletonViewConfiguration();
  std::shared_ptr<const Repr> rep; // const is important for the singletonViewConfiguration optimization.

  friend class CK::Component::ViewReusePoolMap;    // uses attributeShape
};

namespace std {
  template<> struct hash<CKComponentViewConfiguration>
  {
    size_t operator()(const CKComponentViewConfiguration &cl) const;
  };
}

