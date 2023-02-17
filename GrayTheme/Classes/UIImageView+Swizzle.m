//
//  UIImageView+Swizzle.m
//  GrayTheme
//
//  Created by MorganWang on 12/12/2022.
//  Copyright © 2022 MorganWang. All rights reserved.
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
    
    // find self's last superView
    UIView *superView = self;
    NSString *className = @"";
    while (superView.superview) {
        superView = superView.superview;
        className = NSStringFromClass([superView class]);
    }
    
    // if lastSuperView is keyboard window, then do not set grayImage
    if ([className containsString:@"UIRemoteKeyboardWindow"]) {
        [self swizzleSetImage:image];
    } else {
        [self swizzleSetImage:grayImage];
    }
}

@end
