//
//  CKTestTypedPropsComponent.h
//  ComponentKit
//
//  Created by Oliver Rickard on 11/23/16.
//
//

#import <ComponentKit/CKTypedPropsComponent.h>

struct CKTestTypedPropsComponentProps {
  CKRequiredProp<NSString *> string;
  UIFont *font;
};

@interface CKTestTypedPropsComponent : CKTypedPropsComponent

+ (instancetype)newWithProps:(const CKTestTypedPropsComponentProps &)props
                        view:(const CKComponentViewConfiguration &)view
                        size:(const CKComponentSize &)size;

@end
