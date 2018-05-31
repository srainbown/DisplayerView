//
//  DisplayerVolumeSlider.m
//  DisplayerView
//
//  Created by 紫川秀 on 2018/5/17.
//  Copyright © 2018年 dangbei. All rights reserved.
//

#import "DisplayerVolumeSlider.h"

@implementation DisplayerVolumeSlider

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(CGRect)trackRectForBounds:(CGRect)bounds{
    
    bounds = [super trackRectForBounds:bounds];// 必须通过调用父类的trackRectForBounds 获取一个 bounds 值，否则 Autolayout 会失效，UISlider 的位置会跑偏。
    return CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, 3);// 这里面的6即为你想要设置的高度。
    
    
}

@end
