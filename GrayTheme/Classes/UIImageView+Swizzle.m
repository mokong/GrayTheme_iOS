//
//  UIImageView+Swizzle.m
//  WPSFehorizon
//
//  Created by Horizon on 12/12/2022.
//  Copyright © 2022 fehorizon. All rights reserved.
//

#import "UIImageView+Swizzle.h"
#import <objc/runtime.h>
#import "UIImage+Category.h"

@implementation UIImageView (Swizzle)

+ (void)load {
    Class class = [self class];
    SEL originalSelector = @selector(setImage:);
    SEL swizzleSelector = @selector(swizzleSetImage:);
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(class, swizzleSelector);
    
    method_exchangeImplementations(originalMethod, swizzleMethod);
}

- (void)swizzleSetImage:(UIImage *)image {
    UIImage *grayImage = [image anotherGrayImage];
    [self swizzleSetImage:grayImage];
}

@end
