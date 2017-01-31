//
//  CKScrollAnnouncingView.m
//  ComponentKit
//
//  Created by Oliver Rickard on 1/31/17.
//
//

#import "CKScrollAnnouncingView.h"

#import <objc/runtime.h>

#import "CKAssert.h"

static char kAssociatedObjectKey;

@class CKScrollListeningController;

@interface CKScrollListeningToken ()

- (instancetype)initWithController:(CKScrollListeningController *)controller;

@end

@interface CKScrollListeningController : NSObject

- (instancetype)initWithScrollView:(UIScrollView *)scrollView;

- (CKScrollListeningToken *)addScrollListener:(id<CKScrollListener>)listener;
- (void)removeListener:(CKScrollListeningToken *)token;

@end

@implementation CKScrollListeningController
{
  NSMapTable *_tokenToListenerMap;
  UIScrollView *__weak _scrollView;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
{
  if (self = [super init]) {
    _tokenToListenerMap = [NSMapTable strongToWeakObjectsMapTable];
    _scrollView = scrollView;
    [scrollView addObserver:self
                 forKeyPath:@"contentOffset"
                    options:NSKeyValueObservingOptionNew
                    context:NULL];
  }
  return self;
}

- (void)dealloc
{
  CKAssertMainThread();
  // This is just to be safe, but _scrollView should always be nil at this point because this controller is strongly
  // held in an associated object. If this object is being deallocated, it means the scroll view has already died.
  [_scrollView removeObserver:self
                   forKeyPath:@"contentOffset"];
}

- (CKScrollListeningToken *)addScrollListener:(id<CKScrollListener>)listener
{
  CKAssertMainThread();
  CKScrollListeningToken *token = [[CKScrollListeningToken alloc] initWithController:self];
  [_tokenToListenerMap setObject:listener forKey:token];
  return token;
}

- (void)removeListener:(CKScrollListeningToken *)token
{
  CKAssertMainThread();
  [_tokenToListenerMap removeObjectForKey:token];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
  CKAssertMainThread();
  for (CKScrollListeningToken *token in _tokenToListenerMap) {
    id<CKScrollListener> listener = [_tokenToListenerMap objectForKey:token];
    [listener scrollViewDidScroll];
  }
}

@end

@implementation CKScrollListeningToken
{
  __weak CKScrollListeningController *_controller;
}

- (instancetype)initWithController:(CKScrollListeningController *)controller
{
  if (self = [super init]) {
    _controller = controller;
  }
  return self;
}

- (void)removeListener
{
  [_controller removeListener:self];
}

@end

@implementation UIScrollView (CKScrollAnnouncingView)

- (CKScrollListeningToken *)ck_addScrollListener:(id<CKScrollListener>)listener
{
  CKAssertMainThread();
  CKScrollListeningController *controller = objc_getAssociatedObject(self, &kAssociatedObjectKey);
  if (!controller) {
    controller = [[CKScrollListeningController alloc] initWithScrollView:self];
    objc_setAssociatedObject(self, &kAssociatedObjectKey, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return [controller addScrollListener:listener];
}

@end
