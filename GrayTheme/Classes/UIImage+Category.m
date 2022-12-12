//
//  UIImage+Category.m
//  WPSFehorizon
//
//  Created by Horizon on 12/12/2022.
//  Copyright © 2022 fehorizon. All rights reserved.
//

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
