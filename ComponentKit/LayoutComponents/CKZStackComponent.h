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
#import <ComponentKit/CKLayoutComponent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Gravity describes how a child component should be positioned inside a Z-stack that has a larger size.
 */
typedef NS_CLOSED_ENUM(NSInteger, CKZStackComponentGravity) {
  /// Top and left edges of the child component are aligned with the corresponding edges of the stack.
  CKZStackComponentGravityTopLeft,
  /// Top and right edges of the child component are aligned with the corresponding edges of the stack.
  CKZStackComponentGravityTopRight
} NS_SWIFT_NAME(ZStackComponent.Gravity);

/**
 For internal framework use only.

 Please use \c CK::ZStackComponentBuilder instead.
 */
NS_SWIFT_NAME(ZStackComponent.Child)
@interface CKZStackComponentChild : NSObject
@property (nonatomic, strong, readonly) CKComponent *_Nullable component;
@property (nonatomic, assign, readonly) CKZStackComponentGravity gravity;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithComponent:(CKComponent *_Nullable)component;
- (instancetype)initWithComponent:(CKComponent *_Nullable)component gravity:(CKZStackComponentGravity)gravity NS_DESIGNATED_INITIALIZER;
@end

/**
 For internal framework use only.

 Please use \c CK::ZStackComponentBuilder instead.
 */
NS_SWIFT_NAME(ZStackComponent)
@interface CKZStackComponent : CKLayoutComponent

CK_INIT_UNAVAILABLE;

CK_LAYOUT_COMPONENT_INIT_UNAVAILABLE;

- (instancetype)initWithChildren:(NSArray<CKZStackComponentChild *> *)children NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

#if CK_NOT_SWIFT

#import <ComponentKit/ComponentBuilder.h>

namespace CK {
namespace BuilderDetails {
namespace ZStackComponentPropId {
constexpr static auto children = BuilderBasePropId::__max << 1;
constexpr static auto __max = children;
}

template <PropsBitmapType PropsBitmap = 0>
class __attribute__((__may_alias__)) ZStackComponentBuilder
    : public BuilderBase<ZStackComponentBuilder, PropsBitmap> {
 public:
  ZStackComponentBuilder() = default;
      ZStackComponentBuilder(const CK::ComponentSpecContext &context) : BuilderBase<ZStackComponentBuilder, PropsBitmap>{context} { }

  ~ZStackComponentBuilder() = default;

  /**
   Adds a child component with default gravity to this stack.

   @param c component to add.

   @note  Nil components are ignored and are not added to the stack.
  */
  auto &child(NS_RELEASES_ARGUMENT CKComponent *_Nullable c)
  {
    if (c != nil) {
      auto const stackChild = [[CKZStackComponentChild alloc] initWithComponent:c];
      [_children addObject:stackChild];
    }
    return reinterpret_cast<
    ZStackComponentBuilder<PropsBitmap | ZStackComponentPropId::children> &>(*this);
  }

  /**
   Adds a child component with the specified gravity to this stack.

   @param c component to add.
   @param g gravity that will be used to position the component.

   @note  Nil components are ignored and are not added to the stack.
  */
  auto &child(NS_RELEASES_ARGUMENT CKComponent *_Nullable c, CKZStackComponentGravity g)
  {
    if (c != nil) {
      auto const stackChild = [[CKZStackComponentChild alloc] initWithComponent:c gravity:g];
      [_children addObject:stackChild];
    }
    return reinterpret_cast<
    ZStackComponentBuilder<PropsBitmap | ZStackComponentPropId::children> &>(*this);
  }

 private:
  friend BuilderBase<ZStackComponentBuilder, PropsBitmap>;

  /**
  Creates a new component instance with specified properties.

  @note  This method must @b not be called more than once on a given component builder instance.
  */
  NS_RETURNS_RETAINED auto _build() noexcept -> CKZStackComponent *_Nonnull
  {
    constexpr auto hasChildren = PropBitmap::isSet(PropsBitmap, ZStackComponentPropId::children);
    static_assert(hasChildren, "At least one child must be added to the stack using .child().");

    return [[CKZStackComponent alloc] initWithChildren:_children];
  }

 private:
  NSMutableArray<CKZStackComponentChild *> *_Nonnull _children = [NSMutableArray array];
};

}

using ZStackComponentBuilderEmpty = BuilderDetails::ZStackComponentBuilder<>;
using ZStackComponentBuilderContext = BuilderDetails::ZStackComponentBuilder<BuilderDetails::BuilderBasePropId::context>;

/**
 A layout component that lays out its children on top of each other.

 Each child component is sized with the same size constraints as the stack itself and then positioned according to its gravity (see \c CKZStackComponentGravity).
 The final size of the stack is a union of all sizes of its children, e.g. if a stack has 2 children with the sizes of {100, 50} and {50, 100} , the resulting stack size would be
 {100, 100}.
*/
auto ZStackComponentBuilder() -> ZStackComponentBuilderEmpty;

/**
 A layout component that lays out its children on top of each other.

 Each child component is sized with the same size constraints as the stack itself and then positioned according to its gravity (see \c CKZStackComponentGravity).
 The final size of the stack is a union of all sizes of its children, e.g. if a stack has 2 children with the sizes of {100, 50} and {50, 100} , the resulting stack size would be
 {100, 100}.

 @param c The spec context to use.

 @note This factory overload is to be used when a key is required to reference the built component in a spec from the
 @c CK_ANIMATION function.
*/
auto ZStackComponentBuilder(const CK::ComponentSpecContext &c) -> ZStackComponentBuilderContext;
}

#endif
