//
//  DisplayerVolumeView.h
//  DisplayerView
//
//  Created by 紫川秀 on 2018/5/17.
//  Copyright © 2018年 dangbei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayerVolumeSlider.h"

@interface DisplayerVolumeView : UIView

@property (nonatomic, strong) DisplayerVolumeSlider *volumeSlider;

@property (nonatomic, strong) UIImageView *volumeImageView;

@property (nonatomic, strong) UILabel *numLabel;


-(void)fullOrSmall:(BOOL)isFullscreen;

-(void)setNumLabelText:(float)value AndFullOrSmall:(BOOL)isFullscreen;

-(void)setImage:(BOOL)isFullscreen;


@end
