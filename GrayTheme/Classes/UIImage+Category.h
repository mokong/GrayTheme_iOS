//
//  UIImage+Category.h
//  WPSFehorizon
//
//  Created by Horizon on 12/12/2022.
//  Copyright © 2022 fehorizon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Category)

// 不建议使用，内存占用大，且在多图列表上滑动时，影响性能，造成卡顿
//- (UIImage *)grayImage;

// 推荐使用，内存相对小，不卡顿，需注意图片是否包含A通道(ARGB通道)
- (UIImage *)anotherGrayImage;

@end

