//
//  CKTestTypedPropsComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 11/23/16.
//
//

#import "CKTestTypedPropsComponent.h"

#import "CKTypedPropsComponentSubclass.h"
#import "CKLabelComponent.h"

@implementation CKTestTypedPropsComponent

CKTypedPropsComponentConstructorImpl(CKTestTypedPropsComponentProps);

+ (CKComponent *)renderWithProps:(const CKTestTypedPropsComponentProps &)props
                           state:(id)state
                            view:(const CKComponentViewConfiguration &)view
                            size:(const CKComponentSize &)size
{
  return [CKLabelComponent
          newWithLabelAttributes:{
            .string = props.string,
            .font = props.font
          }
          viewAttributes:*view.attributes()
          size:size];
}

@end
