#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "UIColor+Swizzle.h"
#import "UIImage+Category.h"
#import "UIImageView+Swizzle.h"
#import "WKWebView+Swizzle.h"

FOUNDATION_EXPORT double GrayThemeVersionNumber;
FOUNDATION_EXPORT const unsigned char GrayThemeVersionString[];

