//
//  WildeGuessComponentViewController.m
//  WildeGuess
//
//  Created by Oliver Rickard on 2/1/17.
//
//

#import "WildeGuessComponentViewController.h"

#import <ComponentKit/ComponentKit.h>

#import "QuoteContext.h"
#import "QuotesPage.h"
#import "QuotesListComponent.h"

@interface WildeGuessComponentViewController () <CKComponentProvider>

@end

@implementation WildeGuessComponentViewController
{
  CKComponentHostingView *_hostingView;
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(QuoteContext *)context
{
  return [QuotesListComponent
          newWithQuoteContext:context];
}

- (instancetype)init
{
  if (self = [super init]) {

  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];

  _hostingView = [[CKComponentHostingView alloc]
                  initWithComponentProvider:[self class]
                  sizeRangeProvider:
                  [CKComponentFlexibleSizeRangeProvider
                   providerWithFlexibility:
                   CKComponentSizeRangeFlexibilityNone]];
  _hostingView.backgroundColor = [UIColor whiteColor];
  _hostingView.frame = self.view.bounds;
  [self.view addSubview:_hostingView];

  NSSet *imageNames = [NSSet setWithObjects:
                       @"LosAngeles",
                       @"MarketStreet",
                       @"Drops",
                       @"Powell",
                       nil];
  [_hostingView
   updateModel:@YES
   mode:CKUpdateModeSynchronous];
  [_hostingView
   updateContext:[[QuoteContext alloc]
                  initWithImageNames:imageNames]
   mode:CKUpdateModeSynchronous];

  _hostingView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
}

@end
