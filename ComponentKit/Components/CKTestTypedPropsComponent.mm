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

+ (instancetype)newWithProps:(const CKTestTypedPropsComponentProps &)props
                        view:(const CKComponentViewConfiguration &)view
                        size:(const CKComponentSize &)size
{
  return [self newWithPropsStruct:props
                             view:view
                             size:size];
}

+ (CKComponent *)renderWithProps:(const CKTypedComponentStruct &)p
                           state:(id)state
                            view:(const CKComponentViewConfiguration &)view
                            size:(const CKComponentSize &)size
{
  const CKTestTypedPropsComponentProps props = p;
  return [CKLabelComponent
          newWithLabelAttributes:{
            .string = props.string,
            .font = props.font
          }
          viewAttributes:*view.attributes()
          size:size];
}

@end
