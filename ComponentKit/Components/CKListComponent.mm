//
//  CKListComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 1/31/17.
//
//

#import "CKListComponent.h"

#import "CKStackLayoutComponent.h"
#import "CKIncrementalMountComponent.h"
#import "CKMemoizingComponent.h"
#import "CKScrollComponent.h"

@implementation CKListComponent
{
  CKListComponentConfiguration _configuration;
}

+ (instancetype)newWithItems:(NSArray *)items
                     context:(id<NSObject>)context
               configuration:(const CKListComponentConfiguration &)configuration
{
  CKComponentScope scope(self);
  std::vector<CKComponent *>children;

  for (id<NSObject> model in items) {
    CKComponent *child = configuration.componentGenerator(model, context);
    children.push_back(child);
  }

  CKListComponent *c = [super newWithComponent:
                        [CKScrollComponent
                         newWithConfiguration:{
                           .scrollViewDidEndDragging = {scope, @selector(scrollViewDidEndDragging:scrollState:)}
                         }
                         attributes:{}
                         component:
                         [CKIncrementalMountComponent
                          newWithComponent:
                          configuration.collectionComponentGenerator(children, context)]]];
  if (c) {
    c->_configuration = configuration;
  }
  return c;
}

- (void)scrollViewDidEndDragging:(CKComponent *)sender scrollState:(CKScrollViewState)scrollState
{
  if (scrollState.contentSize.width < scrollState.contentSize.height) {
    if (CGRectGetMaxY(scrollState.bounds) > scrollState.contentSize.height - 2.f * CGRectGetHeight(scrollState.bounds)) {
      if (_configuration.nearingListEndAction) {
        _configuration.nearingListEndAction.send(self);
      }
    }
  } else {
    if (CGRectGetMaxX(scrollState.bounds) > scrollState.contentSize.width - 2.f * CGRectGetWidth(scrollState.bounds)) {
      if (_configuration.nearingListEndAction) {
        _configuration.nearingListEndAction.send(self);
      }
    }
  }
}

@end
