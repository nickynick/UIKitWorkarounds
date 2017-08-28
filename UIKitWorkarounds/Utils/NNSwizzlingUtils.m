//
//  NNSwizzlingUtils.m
//  UIKitWorkarounds
//
//  Created by Nick Tymchenko on 28/01/16.
//

#import "NNSwizzlingUtils.h"
#import <objc/runtime.h>

@implementation NNSwizzlingUtils

+ (void)swizzle:(Class)aClass instanceMethod:(SEL)originalSelector withMethod:(SEL)swizzledSelector {
    NSParameterAssert(aClass);
    NSParameterAssert(!sel_isEqual(originalSelector, swizzledSelector));
    
    SEL const sel1 = originalSelector;
    SEL const sel2 = swizzledSelector;
    Method const method1 = class_getInstanceMethod(aClass, sel1);
    Method const method2 = class_getInstanceMethod(aClass, sel2);
    IMP const imp1 = method_getImplementation(method1);
    IMP const imp2 = method_getImplementation(method2);
    char const *const typeEncoding1 = method_getTypeEncoding(method1);
    char const *const typeEncoding2 = method_getTypeEncoding(method2);
    
    NSAssert(strcmp(typeEncoding1, typeEncoding2) == 0, @"Failed to swizzle methods with different signatures.");
    
    class_addMethod(aClass, sel1, imp2, typeEncoding2) || method_setImplementation(method1, imp2);
    class_addMethod(aClass, sel2, imp1, typeEncoding1) || method_setImplementation(method2, imp1);
    
    NSAssert(class_getMethodImplementation(aClass, sel1) == imp2, nil);
    NSAssert(class_getMethodImplementation(aClass, sel2) == imp1, nil);
}

+ (void)swizzle:(Class)aClass classMethod:(SEL)originalSelector withMethod:(SEL)swizzledSelector {
    NSParameterAssert(aClass);
    NSParameterAssert(!sel_isEqual(originalSelector, swizzledSelector));
    
    [self swizzle:object_getClass(aClass) instanceMethod:originalSelector withMethod:swizzledSelector];
}

@end
