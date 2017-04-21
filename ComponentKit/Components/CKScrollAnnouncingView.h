//
//  CKScrollAnnouncingView.h
//  ComponentKit
//
//  Created by Oliver Rickard on 1/31/17.
//
//

#import <UIKit/UIKit.h>

@protocol CKScrollListener <NSObject>

- (void)scrollViewDidScroll;

@end

@interface CKScrollListeningToken : NSObject

- (void)removeListener;

@end

@interface UIScrollView (CKScrollAnnouncingView)

- (CKScrollListeningToken *)ck_addScrollListener:(id<CKScrollListener>)listener;

@end
