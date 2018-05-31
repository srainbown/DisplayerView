//
//  MainViewController.m
//  DisplayerView
//
//  Created by 紫川秀 on 2018/5/17.
//  Copyright © 2018年 dangbei. All rights reserved.
//

#import "MainViewController.h"
#import "DisplayerView.h"

@interface MainViewController ()<KYVedioPlayerDelegate>{
    
    DisplayerView *_displayerView;
    CGRect _playerFrame;
    
}

//是否全屏
@property (nonatomic, assign) BOOL isFullScreen;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor grayColor];
    [self createVedioView];
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    [self prefersStatusBarHidden];
}
#pragma mark -- 创建播放器
-(void)createVedioView{
    _playerFrame = CGRectMake(0, 20, SCREEN_WIDTH, SCREEN_HEIGHT * 211/667);
    _displayerView = [DisplayerView sharedInstance];
    _displayerView.frame = _playerFrame;
    
    [self.view addSubview:_displayerView];
    _displayerView.delegate = self;
    _displayerView.URLString = @"http://220.170.49.105/1/z/h/u/n/zhundgkmzdxkwxrzvizjyjbgsykesq/he.yinyuetai.com/5B3A014EBF507D3887B17D796F2A4F65.flv";
    
    _displayerView.titleLabel.text = @"大圣归来";

    _displayerView.progressColor = C2;
    [_displayerView.topView setHidden:NO];
    
    [_displayerView play];
    
}

#pragma mark - KYVedioPlayerDelegate 播放器委托方法
//点击播放暂停按钮代理方法
-(void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer clickedPlayOrPauseButton:(UIButton *)playOrPauseBtn{
    
    NSLog(@"[KYVedioPlayer] clickedPlayOrPauseButton ");
}
//点击关闭按钮代理方法
-(void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer clickedCloseButton:(UIButton *)closeBtn{
    NSLog(@"[KYVedioPlayer] clickedCloseButton ");
}

//点击全屏按钮代理方法
-(void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer clickedFullScreenButton:(UIButton *)fullScreenBtn{
    NSLog(@"[KYVedioPlayer] clickedFullScreenButton ");
    
    if (fullScreenBtn.isSelected) {//全屏显示
        _isFullScreen = YES;
        kyvedioPlayer.isFullscreen = YES;
        [self.view endEditing:YES];
        [self setNeedsStatusBarAppearanceUpdate];
        [kyvedioPlayer showFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeRight player:kyvedioPlayer withFatherView:self.view];
    }else{
        _isFullScreen = NO;
        kyvedioPlayer.isFullscreen = YES;
        [self setNeedsStatusBarAppearanceUpdate];
        [kyvedioPlayer showSmallScreenWithPlayer:kyvedioPlayer withFatherView:self.view withFrame:_playerFrame];
    }
    
}
//单击WMPlayer的代理方法
-(void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer singleTaped:(UITapGestureRecognizer *)singleTap{

    NSLog(@"[KYVedioPlayer] singleTaped ");
}

//双击WMPlayer的代理方法
-(void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer doubleTaped:(UITapGestureRecognizer *)doubleTap{
    
    NSLog(@"[KYVedioPlayer] doubleTaped ");
}

///播放状态
//播放失败的代理方法
-(void)kyvedioPlayerFailedPlay:(DisplayerView *)kyvedioPlayer playerStatus:(DBCHDisplayerState)state{
    NSLog(@"[KYVedioPlayer] kyvedioPlayerFailedPlay  播放失败");
    //[self closeCurrentCellVedioPlayer];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        kyvedioPlayer.labLoadFailed.hidden  = YES;
    });
}
//准备播放的代理方法
-(void)kyvedioPlayerReadyToPlay:(DisplayerView *)kyvedioPlayer playerStatus:(DBCHDisplayerState)state{
    
    NSLog(@"[KYVedioPlayer] kyvedioPlayerReadyToPlay  准备播放");
    
}
//播放完毕的代理方法
-(void)kyplayerFinishedPlay:(DisplayerView *)kyvedioPlayer{
    
    NSLog(@"[KYVedioPlayer] kyvedioPlayerReadyToPlay  播放完毕");
    
    if (YES == kyvedioPlayer.isFullscreen) {//全屏显示
        
        _isFullScreen = NO;
        kyvedioPlayer.isFullscreen = YES;
        [self setNeedsStatusBarAppearanceUpdate];
        [kyvedioPlayer showSmallScreenWithPlayer:kyvedioPlayer withFatherView:self.view withFrame:_playerFrame];
        
    }else{
        
    }
    
//    [self releasePlayer];
    
}

#pragma mark - NotificationDeviceOrientationChange
-(void)NotificationDeviceOrientationChange:(NSNotification *)notification{
    
    if (_displayerView == nil|| _displayerView.superview==nil){
        return;
    }
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
            NSLog(@"第3个旋转方向---电池栏在下");
        }
            break;
        case UIInterfaceOrientationPortrait:{
            NSLog(@"第0个旋转方向---电池栏在上");
            if (_displayerView.isFullscreen) {
                [self setNeedsStatusBarAppearanceUpdate];
                [_displayerView showSmallScreenWithPlayer:_displayerView withFatherView:self.view withFrame:_playerFrame];
                
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"第2个旋转方向---电池栏在左");
            _displayerView.isFullscreen = YES;
            [self setNeedsStatusBarAppearanceUpdate];
            [_displayerView showFullScreenWithInterfaceOrientation:interfaceOrientation player:_displayerView withFatherView:self.view];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            NSLog(@"第1个旋转方向---电池栏在右");
            _displayerView.isFullscreen = YES;
            [self setNeedsStatusBarAppearanceUpdate];
            [_displayerView showFullScreenWithInterfaceOrientation:interfaceOrientation player:_displayerView withFatherView:self.view];
        }
            break;
        default:
            break;
    }
    
}

//修改状态栏
- (BOOL)prefersStatusBarHidden
{
    return _isFullScreen;
}

/**
 *  注销播放器
 **/
- (void)releasePlayer
{
    //[vedioPlayer resetDisPlayer];
    [_displayerView removeFromSuperview];
    [_displayerView closeDisPlayer];
    _displayerView = nil;
}

- (void)dealloc
{
    [self releasePlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"KYLocalVideoPlayVC deallco");
}

@end
