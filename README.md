# GrayTheme

# iOS界面黑白效果实现

## 背景

iOS APP界面黑白效果实现调研整理，总的来说网上目前有下面几种方法：

- 针对H5网页：注入js代码
- 针对APP原生界面：
    - 针对图片和颜色单独设置
        - hook UIImageView的`setImage`方法，添加UIImage的`Category`，生成灰色图片
        - hook UIColor的`colorWithRed:green:blue:alpha:`方法
    - 针对界面整体处理
        - 创建一个灰色view，设置不响应事件，然后添加在`window`最上层
        - 给App整体添加灰色滤镜

具体如下：

<!--more-->

## 实现

### 针对网页：

针对网页的处理：

- 如果有基类，可以直接在基类初始化`WKWebview`的地方，添加如下代码：

```ObjectiveC

  WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];

  // js脚本

  NSString *jScript = @"var filter = '-webkit-filter:grayscale(100%);-moz-filter:grayscale(100%); -ms-filter:grayscale(100%); -o-filter:grayscale(100%) filter:grayscale(100%);';document.getElementsByTagName('html')[0].style.filter = 'grayscale(100%)';";

  // 注入

  WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];

  [config.userContentController addUserScript:wkUScript];
```

- 如果没有基类，则通过`Swizzle_Method`实现：

```ObjectiveC

  #import "WKWebView+Swizzle.h"

  @implementation WKWebView (Swizzle)

- (void)load {
  Class class = [self class];

  SEL originalSelector = @selector(initWithFrame:configuration:);

  SEL swizzleSelector = @selector(swizzleInitWithFrame:configuration:);

  Method originalMethod = class_getInstanceMethod(class, originalSelector);

  Method swizzleMethod = class_getInstanceMethod(class, swizzleSelector);

  method_exchangeImplementations(originalMethod, swizzleMethod);

  }

- (instancetype)swizzleInitWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration )configuration {
  // js脚本
  NSString jScript = @"var filter = '-webkit-filter:grayscale(100%);-moz-filter:grayscale(100%); -ms-filter:grayscale(100%); -o-filter:grayscale(100%) filter:grayscale(100%);';document.getElementsByTagName('html')0.style.filter = 'grayscale(100%)';";
  // 注入
  WKUserScript \*wkUScript = [WKUserScript alloc initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
               
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

```


### 针对APP原生界面的处理

- 针对颜色和图片处理：

  a. 针对图片的处理：大部分图片的显示都是最后都是调用`UIImageView`的`setImage方法`，所以`hook`这个方法，在显示前生成灰色的图片，然后在赋值，代码如下：
hook `UIImageView`的`setImage方法`： 

```ObjectiveC

#import "UIImageView+Swizzle.h"

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
```

生成灰色图片的代码如下： 

```ObjectiveC

#import <UIKit/UIKit.h>

@interface UIImage (Category)

// 不建议使用，内存占用大，且在多图列表上滑动时，影响性能，造成卡顿

//- (UIImage *)grayImage;

// 推荐使用，内存相对小，不卡顿，需注意图片是否包含A通道(ARGB通道)

- (UIImage *)anotherGrayImage;

@end

// 参考https://blog.csdn.net/iOSxiaodaidai/article/details/113553395

#import "UIImage+Category.h"

@implementation UIImage (Category)

- (UIImage *)grayImage {
    CIImage *beginImage = [CIImage imageWithCGImage:self.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:beginImage forKey:kCIInputImageKey];
    // 修改饱和度为0，范围0-2，默认为1
    [filter setValue:0 forKey:@"inputSaturation"];
    

    // 得到过滤后的图片

    CIImage *outputImage = [filter outputImage];

    // 转换图片，创建基于GPU的CIContext对象

    CIContext *context = [CIContext contextWithOptions:nil];

    CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];

    UIImage *newImage = [UIImage imageWithCGImage:cgImage];

    // 释放C对象

    CGImageRelease(cgImage);

    return newImage;

}

- (UIImage *)anotherGrayImage {
    // 注意这里图片的大小
    CGFloat scale = [UIScreen mainScreen].scale;
    NSInteger width = self.size.width * scale;
    NSInteger height = self.size.height * scale;
    

    // 第一步：创建颜色空间——图片灰度处理（创建灰度空间）

    CGColorSpaceRef colorRef = CGColorSpaceCreateDeviceGray();

    //第二步:颜色空间的上下文(保存图像数据信息)

    //参数1:内存大小(指向这块内存区域的地址)(内存地址)

    //参数2:图片宽

    //参数3:图片高

    //参数4:像素位数(颜色空间,例如:32位像素格式和RGB颜色空间,8位)

    //参数5:图片每一行占用的内存比特数

    //参数6:颜色空间

    //参数7:图片是否包含A通道(ARGB通道)，注意这个参数

    CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, 0, colorRef, kCGImageAlphaPremultipliedLast);

    // 释放内存

    CGColorSpaceRelease(colorRef);

    if (context == nil) {

        return nil;

    }
  
    //第三步:渲染图片(绘制图片)

    //参数1:上下文

    //参数2:渲染区域

    //参数3:源文件(原图片)(说白了现在是一个C/C++的内存区域)

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), self.CGImage);

    //第四步:将绘制颜色空间转成CGImage(转成可识别图片类型)

    CGImageRef grayImageRef = CGBitmapContextCreateImage(context);

    //第五步:将C/C++ 的图片CGImage转成面向对象的UIImage(转成iOS程序认识的图片类型)

    UIImage *dstImage = [UIImage imageWithCGImage:grayImageRef];

    //释放内存

    CGContextRelease(context);

    CGImageRelease(grayImageRef);

    return dstImage;

}

@end
```

  b. 针对颜色的处理：
所有颜色的设置，最终都会走`UIColor`的`colorWithRed:green:blue:alpha:`，所以通过`hook`这个方法，生成灰色的颜色返回并显示，代码如下： 

```ObjectiveC

  #import "UIColor+Swizzle.h"

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

```

- 针对界面整体处理

  a. 方法一：创建一个灰色view，设置不响应事件，然后添加在`window`最上层

``` ObjectiveC

  #import <UIKit/UIKit.h>

  /// 最顶层视图，承载滤镜，自身不接受、不拦截任何触摸事件

  @interface UIViewOverLay : UIView

  @end

  #import "UIViewOverLay.h"

  @implementation UIViewOverLay

  - (instancetype)init {
      self = [super init];
      if (self) {
          [self setupSubviews];
      }
      return self;
  }

  - (instancetype)initWithFrame:(CGRect)frame {
      self = [super initWithFrame:frame];
      if (self) {
          [self setupSubviews];
      }
      return self;
  }

  - (void)setupSubviews {
      self.translatesAutoresizingMaskIntoConstraints = NO;
      self.backgroundColor = [UIColor lightGrayColor];
      self.layer.compositingFilter = @"saturationBlendMode";
  }

  - (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
      // 不处理点击事件
      return nil;
  }

  @end
```

  b. 方法二：给App整体添加灰色滤镜，同样加在`window`最上层

  
```ObjectiveC

  //获取RGBA颜色数值

  CGFloat r,g,b,a;

  [UIColor lightGrayColor getRed:&r green:&g blue:&b alpha:&a];

  //创建滤镜

  id cls = NSClassFromString(@"CAFilter");

  id filter = cls filterWithName:@"colorMonochrome";

  //设置滤镜参数

  [filter setValue:@@(r),@(g),@(b),@(a) forKey:@"inputColor"];

  filter setValue:@(0) forKey:@"inputBias";

  filter setValue:@(1) forKey:@"inputAmount";

  //设置给window

  window.layer.filters = NSArray arrayWithObject:filter;

```


## 总结

iOS APP界面黑白效果实现，不建议图片和颜色单独分开设置，而大部分APP首页不是H5的。所以建议创建一个灰色view，设置不响应事件，然后添加在要置灰的页面或者全局`window`的最上层即可。

## 参考

- [iOS App页面置灰实现](https://blog.z6z8.cn/2021/12/14/ios-app%E9%A1%B5%E9%9D%A2%E7%BD%AE%E7%81%B0%E5%AE%9E%E7%8E%B0/)
- [iOS APP界面黑白化处理（灰度处理）（为悼念日准备）](https://www.jianshu.com/p/601adbf4cdfd)
- [iOS开发特殊日期灰色界面的实现](https://blog.csdn.net/iOSxiaodaidai/article/details/113553395)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

GrayTheme is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'GrayTheme'
```

## Author

MorganWang, a525325614@163.com

## License

GrayTheme is available under the MIT license. See the LICENSE file for more info.
