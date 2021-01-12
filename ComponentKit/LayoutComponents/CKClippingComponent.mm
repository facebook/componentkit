#import <ComponentKit/CKClippingComponent.h>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKLayoutComponent.h>

@interface CKClippingComponent : CKLayoutComponent

CK_INIT_UNAVAILABLE;

CK_LAYOUT_COMPONENT_INIT_UNAVAILABLE;

+ (instancetype)newWithComponent:(CKComponent *)child
                            size:(const CKComponentSize &)size
               clippedDimensions:(CK::ClippingComponentDimensions)dimensions;
@end

@implementation CKClippingComponent {
  CKComponent *_component;
  CK::ClippingComponentDimensions _clippedDimensions;
}

+ (instancetype)newWithComponent:(CKComponent *)component
                            size:(const CKComponentSize &)size
               clippedDimensions:(CK::ClippingComponentDimensions)dimensions
{
  if (component == nil) {
    return nil;
  }

  auto const c =
  [super
   newWithView:
   CK::ViewConfig()
   .viewClass([UIView class])
   .clipsToBounds(true)
   .build()
   size:size];
  c->_component = component;
  c->_clippedDimensions = dimensions;
  return c;
}

- (unsigned int)numberOfChildren
{
  return RCIterable::numberOfChildren(_component);
}

- (id<RCIterable>)childAtIndex:(unsigned int)index
{
  return RCIterable::childAtIndex(self, index, _component);
}

- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  auto const resolvedRange = constrainedSize.intersect(size.resolve(parentSize));

  // Non-const to enable the move out of lambda.
  auto childLayout = [_component layoutThatFits:resolvedRange parentSize:parentSize];

  auto const finalLayout = [&](){
    if (_clippedDimensions == CK::ClippingComponentDimensions::none) {
      return childLayout;
    }

    auto const unconstrainedSize = CKSizeRange{
      constrainedSize.min,
      adjustedMaxSizeForClippedDimensions(constrainedSize.max, _clippedDimensions)
    };
    return [_component layoutThatFits:unconstrainedSize parentSize:parentSize];
  }();

  return {
    self,
    // This component will always have the "normal" size as if the child *was* always constrained.
    resolvedRange.clamp(childLayout.size),
    std::vector<RCLayoutChild> {
      {CGPointZero, finalLayout}
    }
  };
}

static auto adjustedMaxSizeForClippedDimensions(CGSize originalMaxSize, CK::ClippingComponentDimensions clippedDimensions) -> CGSize
{
  switch (clippedDimensions) {
    case CK::ClippingComponentDimensions::width:
      return {INFINITY, originalMaxSize.height};
    case CK::ClippingComponentDimensions::height:
      return {originalMaxSize.width, INFINITY};
    case CK::ClippingComponentDimensions::none:
      CKCFailAssert(@"When no dimension is clipped, the original size constraints must be used");
      return originalMaxSize;
  }
}

@end

auto CK::BuilderDetails::ClippingComponentDetails::factory(CKComponent *component, const CKComponentSize &size, CK::ClippingComponentDimensions dimensions) -> CKComponent *
{
  return [CKClippingComponent newWithComponent:component size:size clippedDimensions:dimensions];
}
