//
//  UIButton+DisplayerButton.m
//  DisplayerView
//
//  Created by 紫川秀 on 2018/5/17.
//  Copyright © 2018年 dangbei. All rights reserved.
//

#import "UIButton+DisplayerButton.h"
#import <objc/runtime.h>

@implementation UIButton (DisplayerButton)

+(UIButton *)creatButtonWithTitile:(NSString *)title TextColor:(UIColor *)textColor Font:(NSInteger)font BackgroundColor:(UIColor *)color setImage:(NSString *)imageName{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    if (imageName) {
        [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    }
    if (title) {
        [button setTitle:title forState:UIControlStateNormal];
    }
    if (textColor) {
        [button setTitleColor:textColor forState:UIControlStateNormal];
    }
    if (font) {
        [button.titleLabel setFont:[UIFont systemFontOfSize:font]];
    }
    [button setBackgroundColor:color];
    return button;
}

+(UIButton *)creatButtonWithNormalImage:(NSString *)imageNormalName setSelectedImage:(NSString*)imageSelectedName;
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    if (imageNormalName) {
        [button setImage:[UIImage imageNamed:imageNormalName] forState:UIControlStateNormal];
    }
    if (imageSelectedName) {
        [button setImage:[UIImage imageNamed:imageSelectedName] forState:UIControlStateSelected];
    }
    return button;
}

+ (CGFloat)getHeightByWidth:(CGFloat)width title:(NSString *)title font:(UIFont *)font
{
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 0)];
    label.text = title;
    label.font = font;
    label.numberOfLines = 0;
    [label sizeToFit];
    CGFloat height = label.frame.size.height;
    return height;
}

+ (CGFloat)getWidthWithTitle:(NSString *)title font:(UIFont *)font {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10000, 0)];
    label.text = title;
    label.font = font;
    [label sizeToFit];
    return label.frame.size.width;
}

@end
