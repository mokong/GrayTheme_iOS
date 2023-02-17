//
//  UIColor+Swizzle.m
//  GrayTheme
//
//  Created by MorganWang on 12/12/2022.
//  Copyright © 2022 MorganWang. All rights reserved.
//

#import "UIColor+Swizzle.h"
#import <objc/runtime.h>

@implementation UIColor (Swizzle)

+ (void)load {
    Class class = [self class];
    SEL originalSelector = @selector(colorWithRed:green:blue:alpha:);
    SEL swizzleSelector = @selector(swizzle_colorWithRed:green:blue:alpha:);
    
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method swizzleMethod = class_getClassMethod(class, swizzleSelector);
    
    method_exchangeImplementations(originalMethod, swizzleMethod);
}

+ (UIColor *)swizzle_colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
    CGFloat grayValue = 0.299*red + 0.587*green + 0.114*blue;
    UIColor *gray = [UIColor colorWithWhite:grayValue alpha:alpha];
    return gray;
}

@end
