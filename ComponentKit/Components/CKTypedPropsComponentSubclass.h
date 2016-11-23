//
//  Header.h
//  ComponentKit
//
//  Created by Oliver Rickard on 11/23/16.
//
//

#import <ComponentKit/CKTypedPropsComponent.h>
#import <ComponentKit/CKComponentSubclass.h>

#define CKTypedPropsComponentConstructorImpl(PropType) \
+ (instancetype)newWithProps:(const PropType &)props \
                        view:(const CKComponentViewConfiguration &)view \
                        size:(const CKComponentSize &)size { \
  return [self newWithPropsStruct:props view:view size:size]; \
} \
+ (CKComponent *)renderWithPropsStruct:(const CKTypedComponentStruct &)props \
                                 state:(id)state \
                                  view:(const CKComponentViewConfiguration &)view \
                                  size:(const CKComponentSize &)size { \
  return [self renderWithProps:props state:state view:view size:size]; \
}

@interface CKTypedPropsComponent ()

+ (instancetype)newWithPropsStruct:(const CKTypedComponentStruct &)props
                              view:(const CKComponentViewConfiguration &)view
                              size:(const CKComponentSize &)size;

+ (CKComponent *)renderWithPropsStruct:(const CKTypedComponentStruct &)props
                                 state:(id)state
                                  view:(const CKComponentViewConfiguration &)view
                                  size:(const CKComponentSize &)size;

@property (nonatomic, assign, readonly) CKTypedComponentStruct props;
@property (nonatomic, strong, readonly) id state;

@end
