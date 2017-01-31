//
//  CKScrollComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 1/31/17.
//
//

#import "CKScrollComponent.h"

#import "CKComponentScope.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKComponentController.h"

@implementation CKScrollComponent
{
  CKComponent *_component;
}

+ (instancetype)newWithAttributes:(const CKViewComponentAttributeValueMap &)passedAttributes
                        component:(CKComponent *)component
{
  CKComponentScope scope(self);

  CKViewComponentAttributeValueMap attributes(passedAttributes);
  CKScrollComponent *c = [super
                          newWithView:{
                            {[UIScrollView class]},
                            std::move(attributes)
                          }
                          size:{}];
  if (c) {
    c->_component = component;
  }
  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKComponentLayout l = [_component layoutThatFits:{} parentSize:parentSize];
  return {self, constrainedSize.clamp(l.size), {{{0,0}, l}}};
}

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent
{
  CK::Component::MountResult result = [super mountInContext:context
                                                       size:size
                                                   children:children
                                             supercomponent:supercomponent];
  if (children && !children->empty()) {
    [((UIScrollView *)self.viewContext.view) setContentSize:children->at(0).layout.size];
  }
  return result;
}

@end

@interface CKScrollComponentController : CKComponentController<CKScrollComponent *> <UIScrollViewDelegate>

@end

@implementation CKScrollComponentController

- (UIScrollView *)scrollView
{
  return (UIScrollView *)self.view;
}

- (void)didMount
{
  [super didMount];
  self.scrollView.delegate = self;

  // TODO: reconfigure the scroll view on mounting.
}

- (void)didRemount
{
  [super didRemount];
  self.scrollView.delegate = self;
}

- (void)willUnmount
{
  [super willUnmount];
  self.scrollView.delegate = nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{

}

@end
