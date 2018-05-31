//
//  DisplayerVolumeView.m
//  DisplayerView
//
//  Created by 紫川秀 on 2018/5/17.
//  Copyright © 2018年 dangbei. All rights reserved.
//

#import "DisplayerVolumeView.h"

@implementation DisplayerVolumeView

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = JXColor(0, 0, 0,0.5);
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 4;
        
        //创建滑块
        [self createVolumeSlider];
        //创建imageView
        [self createImageView];
        //创建numLabel
        [self createNumLabel];
        
    }
    
    return self;
}
-(void)fullOrSmall:(BOOL)isFullscreen{
    
    if (isFullscreen == YES) {
        
        [_volumeSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.mas_centerY);
            make.width.mas_equalTo(SCREEN_WIDTH/375 * 120);
            make.height.mas_equalTo(@3);
            make.centerX.mas_equalTo(self.mas_centerX);
        }];
        
        [_numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(self.centerX);
            make.top.mas_equalTo(self.top).offset(SCREEN_HEIGHT/667 * 12);
        }];
        
        [_volumeImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.bottom).offset(- SCREEN_HEIGHT/667 * 10);
            make.centerX.mas_equalTo(self.centerX);
        }];
        
        [self setNeedsUpdateConstraints];
        [self updateConstraintsIfNeeded];
        
    }else{
        
        [_volumeSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.mas_centerY);
            make.centerX.mas_equalTo(self.mas_centerX);
            make.width.mas_equalTo(SCREEN_HEIGHT/667 * 96);
            make.height.mas_equalTo(SCREEN_WIDTH/375 * 20);
        }];
        
        [_volumeImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.mas_bottom).offset(-SCREEN_HEIGHT/667 * 6);
            make.centerX.mas_equalTo(self.mas_centerX);
        }];
        
        [_numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(self.mas_centerX);
            make.top.mas_equalTo(self.top).offset(SCREEN_HEIGHT/667 * 6);
        }];
        
    }
    
}
-(void)createVolumeSlider{
    
    _volumeSlider = [[DisplayerVolumeSlider alloc]init];
    [self addSubview:_volumeSlider];
    [_volumeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.center);
        make.width.mas_equalTo(SCREEN_HEIGHT/667 * 96);
        make.height.mas_equalTo(SCREEN_WIDTH/375 * 20);
    }];
    
    _volumeSlider.userInteractionEnabled = NO;
    //通过设置图片修改滑块圆点大小
    [_volumeSlider setThumbImage:[UIImage imageNamed:@"ic_dot"] forState:UIControlStateNormal];
    //设置最小处的图片
    //    _volumeSlider.minimumValueImage = [UIImage imageNamed:@"xiangqing_icon_sound"];
    //设置最小值
    _volumeSlider.minimumValue = 0;
    //设置最大值
    _volumeSlider.maximumValue = 1;
    //设置可连续变化
    _volumeSlider.continuous = YES;
    //    //设置滑块划过去的颜色
    _volumeSlider.minimumTrackTintColor = C2;
    //    [_volumeSlider setMinimumTrackImage:[UIImage imageNamed:@"3"] forState:UIControlStateNormal];
    //    //设置滑块未划过去的颜色
    _volumeSlider.maximumTrackTintColor = C0_2;
    //    [_volumeSlider setMaximumTrackImage:[UIImage imageNamed:@"5"] forState:UIControlStateNormal];
    
    //设置滑球的颜色
    //    slider.thumbTintColor = [UIColor redColor];
    //让滑块竖立
    _volumeSlider.transform = CGAffineTransformMakeRotation(-M_PI/2);
    
}

-(void)createImageView{
    
    WS(weakSelf);
    
    _volumeImageView = [[UIImageView alloc]init];
    [self addSubview:_volumeImageView];
    [_volumeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(weakSelf.bottom).offset(-SCREEN_HEIGHT/667 * 6);
        make.centerX.mas_equalTo(weakSelf.centerX);
    }];
    
    //    _imageView.image = [UIImage imageNamed:@"xiangqing_icon_sound"];
    
}

-(void)createNumLabel{
    
    _numLabel = [[UILabel alloc]init];
    [self addSubview:_numLabel];
    [_numLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(self.top).offset(SCREEN_HEIGHT/667 * 6);
    }];
    _numLabel.font = [UIFont systemFontOfSize:T6];
    _numLabel.textColor = C0;
    
}

-(void)setNumLabelText:(float)value AndFullOrSmall:(BOOL)isFullscreen{
    
    int num = value *100;
    _numLabel.text = [NSString stringWithFormat:@"%d",num];
    
    if (isFullscreen == YES) {
        
        if (0 == num) {
            _volumeImageView.image = [UIImage imageNamed:@"quanpin_icon_sound off"];
        }else{
            _volumeImageView.image = [UIImage imageNamed:@"quanpin_icon_sound"];
        }
        
    }else{
        
        if (0 == num) {
            _volumeImageView.image = [UIImage imageNamed:@"xiangqing_icon_sound off"];
        }else{
            _volumeImageView.image = [UIImage imageNamed:@"xiangqing_icon_sound"];
        }
        
    }
    
}

-(void)setImage:(BOOL)isFullscreen{
    
    if (isFullscreen == YES) {
        _volumeImageView.image = [UIImage imageNamed:@"quanpin_icon_light"];
    }else{
        _volumeImageView.image = [UIImage imageNamed:@"xiangqing_icon_light"];
    }
}


@end
