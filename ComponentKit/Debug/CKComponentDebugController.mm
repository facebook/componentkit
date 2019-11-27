/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentDebugController.h"

#import <UIKit/UIKit.h>

#import <mutex>

#import <ComponentKit/CKMutex.h>

#import "CKComponent+UIView.h"
#import "CKComponent.h"
#import "CKComponentAnimation.h"
#import "CKComponentHostingView.h"
#import "CKComponentHostingViewInternal.h"
#import "CKComponentInternal.h"
#import "CKComponentRootView.h"

#import <objc/runtime.h>

/** Posted on the main thread when debug mode changes. Currently not exposed publicly. */
static NSString *const CKComponentDebugModeDidChangeNotification = @"CKComponentDebugModeDidChangeNotification";

@interface CKComponentDebugView : UIView
@end

@implementation CKComponentDebugView
{
  BOOL _selfDestructOnHiding;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:0.1];
    self.layer.borderColor = [UIColor colorWithRed:0.2 green:0.7 blue: 0.6 alpha: 0.5].CGColor;
    if ([UIScreen mainScreen].scale > 1) {
      self.layer.borderWidth = 0.5f;
    } else {
      self.layer.borderWidth = 1.0f;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(debugModeDidChange) name:CKComponentDebugModeDidChangeNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)debugModeDidChange
{
  if ([CKComponentDebugController debugMode]) {
    _selfDestructOnHiding = NO;
  } else {
    if ([self isHidden]) {
      [self removeFromSuperview];
    } else {
      // We make a best-effort to "reflow" all visible components when toggling debug mode, but this doesn't affect
      // off-window components. Wait to self-destruct until the debug view is hidden for reuse.
      _selfDestructOnHiding = YES;
    }
  }
}

- (void)setHidden:(BOOL)hidden
{
  [super setHidden:hidden];
  if (_selfDestructOnHiding && hidden) {
    [self removeFromSuperview];
  }
}

@end

@implementation CKComponentDebugController

static BOOL _debugMode;

#pragma mark - dcomponents / Debug Views For Components

+ (void)setDebugMode:(BOOL)debugMode
{
  _debugMode = debugMode;
  [self reflowComponents];
  [[NSNotificationCenter defaultCenter] postNotificationName:CKComponentDebugModeDidChangeNotification object:self];
}

+ (BOOL)debugMode
{
  return _debugMode;
}

CK::Component::MountContext CKDebugMountContext(Class componentClass,
                                                const CK::Component::MountContext &context,
                                                const CKComponentViewConfiguration &viewConfiguration,
                                                const CGSize size)
{
  if (viewConfiguration.viewClass().hasView()) {
    return context; // no need for a debug view if the component has a view.
  }

  // Avoid the static destructor fiasco, use a pointer:
  static std::unordered_map<Class, CKComponentViewConfiguration> *debugViewConfigurations =
  new std::unordered_map<Class, CKComponentViewConfiguration>();

  auto it = debugViewConfigurations->find(componentClass);
  if (it == debugViewConfigurations->end()) {
    NSString *debugViewClassName = [NSStringFromClass(componentClass) stringByAppendingString:@"View_Debug"];
    CKCAssertNil(NSClassFromString(debugViewClassName), @"Didn't expect class to already exist");
    Class debugViewClass = objc_allocateClassPair([CKComponentDebugView class], [debugViewClassName UTF8String], 0);
    CKCAssertNotNil(debugViewClass, @"Expected class to be created");
    objc_registerClassPair(debugViewClass);
    debugViewConfigurations->insert({componentClass, CKComponentViewConfiguration(debugViewClass)});
  }

  UIView *debugView = context.viewManager->viewForConfiguration(componentClass, debugViewConfigurations->at(componentClass));
  debugView.frame = {context.position, size};
  return context.childContextForSubview(debugView, NO);
}

#pragma mark - Synchronous Reflow

static NSHashTable<id<CKComponentDebugReflowListener>> *reflowListeners;
static std::mutex reflowMutex;

+ (void)reflowComponents
{
  [self enumerateListeners:^(id<CKComponentDebugReflowListener> listener) {
    [listener didReceiveReflowComponentsRequest];
  }];
}

+ (void)reflowComponentsWithTreeNodeIdentifier:(CKTreeNodeIdentifier)treeNodeIdentifier
{
  [self enumerateListeners:^(id<CKComponentDebugReflowListener> listener) {
    [listener didReceiveReflowComponentsRequestWithTreeNodeIdentifier:treeNodeIdentifier];
  }];
}

+ (void)enumerateListeners:(void(^)(id<CKComponentDebugReflowListener>))block
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{ [self enumerateListeners:block]; });
    return;
  }
  NSArray<id<CKComponentDebugReflowListener>> *copiedListeners;
  {
    std::lock_guard<std::mutex> l(reflowMutex);
    copiedListeners = [reflowListeners allObjects];
  }
  for (id<CKComponentDebugReflowListener> listener in copiedListeners) {
    block(listener);
  }
}

+ (void)registerReflowListener:(id<CKComponentDebugReflowListener>)listener
{
  if (listener == nil) {
    return;
  }
  std::lock_guard<std::mutex> l(reflowMutex);
  if (reflowListeners == nil) {
    reflowListeners = [NSHashTable weakObjectsHashTable];
  }
  [reflowListeners addObject:listener];
}

@end
