//
//  WKWebView+Swizzle.m
//  WPSFehorizon
//
//  Created by Horizon on 12/12/2022.
//  Copyright © 2022 fehorizon. All rights reserved.
//

#import "WKWebView+Swizzle.h"

@implementation WKWebView (Swizzle)

+ (void)load {
    Class class = [self class];
    SEL originalSelector = @selector(initWithFrame:configuration:);
    SEL swizzleSelector = @selector(swizzleInitWithFrame:configuration:);
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(class, swizzleSelector);
    
    method_exchangeImplementations(originalMethod, swizzleMethod);
}

- (instancetype)swizzleInitWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    // js脚本
    NSString *jScript = @"var filter = '-webkit-filter:grayscale(100%);-moz-filter:grayscale(100%); -ms-filter:grayscale(100%); -o-filter:grayscale(100%) filter:grayscale(100%);';document.getElementsByTagName('html')[0].style.filter = 'grayscale(100%)';";
    // 注入
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
                 
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
       [wkUController addUserScript:wkUScript];
    // 配置对象
    WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
    wkWebConfig.userContentController = wkUController;
    configuration = wkWebConfig;
    WKWebView *webView = [self swizzleInitWithFrame:frame configuration:configuration];
    return webView;
}

@end
