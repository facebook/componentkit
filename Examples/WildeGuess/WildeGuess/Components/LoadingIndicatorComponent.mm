//
//  LoadingIndicatorComponent.m
//  WildeGuess
//
//  Created by Oliver Rickard on 2/4/17.
//
//

#import "LoadingIndicatorComponent.h"

#import <ComponentKit/CKCenterLayoutComponent.h>

@interface LoadingIndicatorComponentView : UIView

@end

@implementation LoadingIndicatorComponentView
{
  UIActivityIndicatorView *_activityIndicatorView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicatorView.hidesWhenStopped = NO;
    [self addSubview:_activityIndicatorView];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _activityIndicatorView.frame = self.bounds;
}

- (void)setHidden:(BOOL)hidden
{
  BOOL wasHidden = self.hidden;
  [super setHidden:hidden];
  if (hidden != wasHidden) {
    if (hidden) {
      [_activityIndicatorView stopAnimating];
    } else {
      [_activityIndicatorView startAnimating];
    }
  }
}

- (void)didMoveToWindow
{
  [super didMoveToWindow];
  if (!self.hidden) {
    [_activityIndicatorView startAnimating];
  }
}

@end

@implementation LoadingIndicatorComponent

+ (instancetype)new
{
  return [super newWithComponent:
          [CKCenterLayoutComponent
           newWithCenteringOptions:{}
           sizingOptions:{}
           child:
           [CKComponent
            newWithView:{
              [LoadingIndicatorComponentView class]
            }
            size:{}]
           size:{
             .minWidth = 50,
             .minHeight = 50
           }]];
}

@end
