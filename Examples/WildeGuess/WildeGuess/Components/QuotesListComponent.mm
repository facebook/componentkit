//
//  QuotesListComponent.m
//  WildeGuess
//
//  Created by Oliver Rickard on 2/1/17.
//
//

#import "QuotesListComponent.h"

#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKListComponent.h>
#import <ComponentKit/CKStackLayoutComponent.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKUniqueComponent.h>

#import "QuoteComponent.h"
#import "QuoteModelController.h"
#import "QuotesPage.h"
#import "QuoteContext.h"

@interface QuotesListComponentController : CKComponentController<QuotesListComponent *>

- (void)loadMore;

@end

@implementation QuotesListComponent

+ (instancetype)newWithQuoteContext:(QuoteContext *)quoteContext
{
  CKComponentScope scope(self);

  return [super newWithComponent:
          [CKListComponent
           newWithItems:scope.state()
           context:quoteContext
           configuration:{
             .componentGenerator = ^CKComponent *(id<NSObject> model, id<NSObject> context) {
               return [QuoteComponent newWithQuote:(Quote *)model
                                           context:(QuoteContext *)context];
             },
             .collectionComponentGenerator = ^CKComponent *(const std::vector<CKComponent *> children, id<NSObject> context) {
               std::vector<CKStackLayoutComponentChild> stackChildren;
               int index = 0;
               for (const auto &c : children) {
                 stackChildren.push_back({
                   [CKUniqueComponent
                    newWithIdentifier:@(index)
                    component:c]
                 });
                 index++;
               }
               return [CKStackLayoutComponent
                       newWithView:{}
                       size:{
                         .minWidth = CKRelativeDimension::Percent(1),
                         .maxWidth = CKRelativeDimension::Percent(1)
                       }
                       style:{
                         .direction = CKStackLayoutDirectionVertical,
                         .alignItems = CKStackLayoutAlignItemsStretch
                       }
                       children:stackChildren];
             },
             .nearingListEndAction = {scope, @selector(loadMore)}
           }]];
}

@end

@implementation QuotesListComponentController
{
  BOOL _isLoading;
  QuoteModelController *_modelController;
}

- (instancetype)initWithComponent:(QuotesListComponent *)component
{
  if (self = [super initWithComponent:component]) {
    _modelController = [[QuoteModelController alloc] init];
    _isLoading = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
      [component updateState:^NSArray *(NSArray *currentItems) {
        _isLoading = NO;
        return [_modelController fetchNewQuotesPageWithCount:30].quotes;
      } mode:CKUpdateModeAsynchronous];
    });
  }
  return self;
}

- (void)loadMore
{
  if (_isLoading) {
    return;
  }
  _isLoading = YES;
  [self.component updateState:^NSArray *(NSArray *currentItems) {
    _isLoading = NO;
    NSMutableArray *output = [NSMutableArray arrayWithArray:currentItems];
    [output addObjectsFromArray:[_modelController fetchNewQuotesPageWithCount:5].quotes];
    return output;
  } mode:CKUpdateModeAsynchronous];
}

@end
