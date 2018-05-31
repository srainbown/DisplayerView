//
//  UIButton+DisplayerButton.h
//  DisplayerView
//
//  Created by 紫川秀 on 2018/5/17.
//  Copyright © 2018年 dangbei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (DisplayerButton)

/**
 快速创建button
 
 @param title 文字
 @param textColor 文字颜色
 @param font 文字大小
 @param color 背景色
 @param imageName 图片
 @return 按钮
 */
+(UIButton *)creatButtonWithTitile:(NSString *)title TextColor:(UIColor *)textColor Font:(NSInteger)font BackgroundColor:(UIColor *)color setImage:(NSString *)imageName;


/**
 快速创建button
 @param imageNormalName  正常图片
 @param imageSelectedName  被选择图片
 @return 按钮
 */
+(UIButton *)creatButtonWithNormalImage:(NSString *)imageNormalName setSelectedImage:(NSString*)imageSelectedName;
/**
 label分类，自适应高度和宽度
 
 @param width 传入的宽度
 @param title 传入的内容
 @param font  传入的大小
 
 @return 自适应的高度
 */
+ (CGFloat)getHeightByWidth:(CGFloat)width title:(NSString *)title font:(UIFont*)font;


/**
 label自适应的宽度
 
 @param title 传入的内容
 @param font  传入的大小
 
 @return 自适应的高度
 */
+ (CGFloat)getWidthWithTitle:(NSString *)title font:(UIFont *)font;


@end
