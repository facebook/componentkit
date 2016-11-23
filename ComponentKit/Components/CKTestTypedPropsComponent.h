//
//  CKTestTypedPropsComponent.h
//  ComponentKit
//
//  Created by Oliver Rickard on 11/23/16.
//
//

#import <ComponentKit/CKTypedPropsComponent.h>

struct CKTestTypedPropsComponentProps {
  NSString *string;
  UIFont *font;
};

@interface CKTestTypedPropsComponent : CKTypedPropsComponent

CKTypedPropsComponentConstructor(CKTestTypedPropsComponentProps);

@end
