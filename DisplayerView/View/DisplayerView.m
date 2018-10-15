//
//  DisplayerView.m
//  DisplayerView
//
//  Created by 紫川秀 on 2018/5/17.
//  Copyright © 2018年 dangbei. All rights reserved.
//

#import "DisplayerView.h"
#import "Reachability.h"
#import "DisplayerSlider.h"

#define kHalfWidth self.frame.size.width * 0.5
#define kHalfHeight self.frame.size.height * 0.5

#define kShowNextlabTime          10.0

static void *PlayViewCMTimeValue = &PlayViewCMTimeValue;

static void *PlayViewStatusObservationContext = &PlayViewStatusObservationContext;

//定义一个播放器单例
__strong static DisplayerView *sharedDisPlayerManager = nil;


@interface DisplayerView() <UIGestureRecognizerDelegate>{
    Reachability * _hostReach;
}
@property (nonatomic,assign)CGPoint firstPoint;
@property (nonatomic,assign)CGPoint secondPoint;
@property (nonatomic, strong)NSDateFormatter *dateFormatter;
//监听播放起状态的监听者
@property (nonatomic ,strong) id playbackTimeObserver;

//获取输出流的地址
@property(nonatomic, strong) AVPlayerItemVideoOutput * videoOutPut;

@property(nonatomic, strong) AVAssetImageGenerator * imgGenerator;

@property (nonatomic, strong) AVURLAsset * avURLasset;

//视频进度条的单击事件
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, assign) CGPoint originalPoint;
@property (nonatomic, assign) BOOL isDragingSlider;             //是否点击了按钮的响应事件

/**
 *  显示播放时间的UILabel
 */
@property (nonatomic,strong) UILabel        *leftTimeLabel;
@property (nonatomic,strong) UILabel        *rightTimeLabel;
@property (nonatomic,strong) UIImage        *screenShotImg;


/**
 * 亮度的进度条
 */
@property (nonatomic, strong) UISlider       *lightSlider;
@property (nonatomic, strong) DisplayerSlider       *progressSlider;
@property (nonatomic, strong) UISlider       *volumeSlider;


@property (nonatomic, strong) MPVolumeView   *mpVolumeView;           //系统音量显示图
//系统滑条
@property (nonatomic, strong) UISlider                  *systemSlider;
@property (nonatomic, strong) UITapGestureRecognizer    *singleTap;          //单击

@property (nonatomic, strong) UIProgressView            *loadingProgress;      //loading
@property (nonatomic, strong) UIProgressView            *screenSlider;         //外部进度条
@property (nonatomic, strong) UIProgressView            *screenCacheSlider;    //外部缓存进度条
@property (nonatomic, strong) UILabel                   *labNetWorkMention;    //网络提示语
@property (nonatomic, strong) UIButton                  *btnLeft;              //停止播放
@property (nonatomic, strong) UIButton                  *btnRight;             //继续播放


/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection           panDirection;
/** 用来保存快进的总时长 */
@property (nonatomic, assign) CGFloat                sumTime;
/** 是否正在拖拽 */
@property (nonatomic, assign) BOOL                   isDragged;

@property (nonatomic, assign) BOOL                   is4GNetWork;   //是4G网络


@end

@implementation DisplayerView


@synthesize isPlaying;

- (instancetype)init{
    self = [super init];
    if (self){
        [self initPlayer];
        self.detailState = DBCHDisplayerStateStopped;
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSError * audioSessionError;
        [audioSession setCategory:AVAudioSessionCategoryPlayback  error:&audioSessionError];
        
        if (_isFromDownLoadedView == NO) {
            //开启网络状况的监听
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
                _hostReach = [Reachability reachabilityWithHostName:@"www.baidu.com"];//会出现两次到监听方法中去的情况
                //网络监听
                //        hostReach = [Reachability reachabilityForInternetConnection];
                [_hostReach startNotifier];  //开始监听,会启动一个run loop

            });
        }
        
    }
    return self;
}

//生成播放器单例
+(DisplayerView *)sharedInstance{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDisPlayerManager = [[DisplayerView alloc] init];
    });
    
    return sharedDisPlayerManager;
}

/**
 *  storyboard、xib的初始化方法
 */
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initPlayer];
}


- (void)setIsFromDownLoadedView:(BOOL)isFromDownLoadedView{
    _isFromDownLoadedView = isFromDownLoadedView;
    [_hostReach stopNotifier];
}

//监听到网络状态改变
- (void) reachabilityChanged: (NSNotification* )note{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    [self updateInterfaceWithReachability: curReach];
}


//处理连接改变后的情况
- (void) updateInterfaceWithReachability: (Reachability*) curReach{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * strNetWork = [defaults valueForKey:KNetWorkPlayer];
    if (nil == strNetWork) {
        strNetWork = @"0";
    }
    //允许播放
    if (1 == [strNetWork intValue]) {
        return;
    }else{
        //对连接改变做出响应的处理动作。
        NetworkStatus status = [curReach currentReachabilityStatus];
        if(ReachableViaWWAN == status){
            self.is4GNetWork = YES;
            ZCXLog(@"网络状态：4G网络");
            //暂停下载进度和播放进度
            //[self removeDisPlayer];
            [self pause];
            //提示用户网络切换
            if (self.netWorkView.isHidden) {
                [self.netWorkView setHidden:NO];
            }
        }
        else if(ReachableViaWiFi == status){
            self.is4GNetWork = NO;
            ZCXLog(@"网络状态：WI-FI");
            //继续播放
            //提示用户网络切换
            [self.netWorkView setHidden:YES];
            //不是暂停的时候，继续播放
            if (!self.btnPlayOrPause.isSelected) {
                [self play];
            }

        }else{
            ZCXLog(@"网络状态：无网络状态！");
            self.is4GNetWork = NO;
        }

    }
}

/**
 *  初始化KYVedioPlayer的控件，添加手势，添加通知，添加kvo等
 */
-(void)initPlayer{
    self.seekTime = 0.00;
    self.isAutoDismissBottomView = YES;  //自动隐藏
    self.isForbiddenFullScreen = YES;    //默认可以全屏
    self.isDragingSlider = NO;
    self.is4GNetWork = NO;
    self.isFromDetailView = NO;
    
    //cell中的背景
    self.bgImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"black"]];
    self.bgImgView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.bgImgView];
    
    //添加loading视图
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self addSubview:self.loadingView];
    
    //添加顶部视图
    self.topView = [[UIView alloc]init];
    self.topView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.0];
    [self addSubview:self.topView];
    
    //添加底部视图
    self.bottomView = [[UIView alloc]init];
    self.bottomView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.bottomView];
    
    //添加暂停和开启按钮
    self.btnPlayOrPause = [[UIButton alloc]init];
    self.btnPlayOrPause.showsTouchWhenHighlighted = YES;
    [self.btnPlayOrPause addTarget:self action:@selector(PlayOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnPlayOrPause setImage:[UIImage imageNamed:@"pause_icon"] ?: [UIImage imageNamed:@"pause_icon"] forState:UIControlStateNormal];
    [self.btnPlayOrPause setImage:[UIImage imageNamed:@"play_icon"] ?: [UIImage imageNamed:@"play_white_icon"] forState:UIControlStateSelected];
    [self addSubview:self.btnPlayOrPause];
    
    //创建亮度的进度条
    self.lightSlider = [[UISlider alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.lightSlider.hidden = YES;
    self.lightSlider.minimumValue = 0;
    self.lightSlider.maximumValue = 1;
    //进度条的值等于当前系统亮度的值,范围都是0~1
    self.lightSlider.value = [UIScreen mainScreen].brightness;
    [self addSubview:self.lightSlider];
    
    _mpVolumeView = [[MPVolumeView alloc]init];
    //[self addSubview:_volumeView];
    _mpVolumeView.frame = CGRectMake(-1000, -100, 100, 100);
    [_mpVolumeView sizeToFit];
    
    self.systemSlider = [[UISlider alloc]init];
    self.systemSlider.backgroundColor = [UIColor clearColor];
    for (UIControl *view in _mpVolumeView.subviews) {
        if ([view.superclass isSubclassOfClass:[UISlider class]]) {
            self.systemSlider = (UISlider *)view;
        }
    }
    self.systemSlider.autoresizesSubviews = NO;
    self.systemSlider.autoresizingMask = UIViewAutoresizingNone;
    //[self addSubview:self.systemSlider];
    //设置声音滑块
    self.volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.volumeSlider.tag = 1000;
    self.volumeSlider.hidden = YES;
    self.volumeSlider.minimumValue = self.systemSlider.minimumValue;
    self.volumeSlider.maximumValue = self.systemSlider.maximumValue;
    self.volumeSlider.value = self.systemSlider.value;
    [self.volumeSlider addTarget:self action:@selector(updateSystemVolumeValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.volumeSlider];
    
    //进度条
    self.progressSlider = [[DisplayerSlider alloc]init];
    self.progressSlider.minimumValue = 0.0;
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"ic_dot"] ?: [UIImage imageNamed:@"ic_dot"]  forState:UIControlStateNormal];
    self.progressSlider.maximumTrackTintColor = [UIColor clearColor];
    self.progressSlider.value = 0.0;//指定初始值
    //进度条的拖拽事件
    [self.progressSlider addTarget:self action:@selector(stratDragSlide:)  forControlEvents:UIControlEventValueChanged];
    //进度条的点击事件
    [self.progressSlider addTarget:self action:@selector(updateProgress:) forControlEvents:UIControlEventTouchUpInside];
    //给进度条添加单击手势
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapGesture:)];
    self.tap.delegate = self;
    [self.progressSlider addGestureRecognizer:self.tap];
    self.progressSlider.backgroundColor = [UIColor clearColor];
    [self.bottomView addSubview:self.progressSlider];
    
    //loadingProgress
    self.loadingProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.loadingProgress.progressTintColor = [UIColor clearColor];
    self.loadingProgress.trackTintColor    = [UIColor lightGrayColor];
    [self.bottomView addSubview:self.loadingProgress];
    [self.loadingProgress setProgress:0.0 animated:NO];
    
    //外部进度条screenCacheSlider;
    self.screenCacheSlider = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.screenCacheSlider.progressTintColor = [UIColor clearColor];
    self.screenCacheSlider.trackTintColor    = [UIColor lightGrayColor];
    [self addSubview:self.screenCacheSlider];
    [self.screenCacheSlider setProgress:0.0 animated:NO];
    
    //外部缓存进度条
    self.screenSlider = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.screenSlider.progressTintColor = [UIColor clearColor];
    self.screenSlider.trackTintColor    = [UIColor clearColor];
    [self addSubview:self.screenSlider];
    [self.screenSlider setProgress:0.0 animated:NO];
    
    //全屏按钮
    self.btnFullScreen = [[UIButton alloc]init];
    self.btnFullScreen.showsTouchWhenHighlighted = YES;
    [self.btnFullScreen addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnFullScreen setImage:[UIImage imageNamed:@"full_icon"] ?: [UIImage imageNamed:@"full_icon"] forState:UIControlStateNormal];
    [self.btnFullScreen setImage:[UIImage imageNamed:@"Exit full screen_icon"] ?: [UIImage imageNamed:@"Exit full screen_icon"] forState:UIControlStateSelected];
    [self.bottomView addSubview:self.btnFullScreen];
    
    //关闭按钮
    _closeBtn = [[UIButton alloc]init];
    _closeBtn.showsTouchWhenHighlighted = YES;
    [_closeBtn addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    [_closeBtn setImage:[UIImage imageNamed:@"back_white_icon"] ?: [UIImage imageNamed:@"back_white_icon"] forState:UIControlStateNormal];
    [self.closeBtn setHidden:YES];
    [self.topView addSubview:_closeBtn];
    
    //左边时间
    self.leftTimeLabel = [[UILabel alloc]init];
    self.leftTimeLabel.textAlignment = NSTextAlignmentLeft;
    self.leftTimeLabel.textColor = [UIColor whiteColor];
    self.leftTimeLabel.backgroundColor = [UIColor clearColor];
    self.leftTimeLabel.font = [UIFont systemFontOfSize:11];
    self.leftTimeLabel.text = @"00:00";
    [self.bottomView addSubview:self.leftTimeLabel];
    
    //右边时间
    self.rightTimeLabel = [[UILabel alloc]init];
    self.rightTimeLabel.textAlignment = NSTextAlignmentRight;
    self.rightTimeLabel.textColor = [UIColor whiteColor];
    self.rightTimeLabel.backgroundColor = [UIColor clearColor];
    self.rightTimeLabel.font = [UIFont systemFontOfSize:11];
    self.rightTimeLabel.text = (self.allTime == nil? @"00:00" : self.allTime);
    [self.bottomView addSubview:self.rightTimeLabel];
    
    //标题
    self.titleLabel = [[UILabel alloc]init];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = [UIFont systemFontOfSize:T3];
    self.titleLabel.text = @"我嗯是厚度是那 u 是你得牛";
    [self.topView addSubview:self.titleLabel];
    
    [self makeConstraints];
    //添加网络切换方法
    //添加底部视图netWorkView
    self.netWorkView = [[UIView alloc]init];
    [self addSubview:self.netWorkView];
    
    [self.netWorkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self);
        make.height.mas_equalTo(self);
        make.center.mas_equalTo(self);
    }];
    self.netWorkView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];

    
    //labNetWorkMention(@"您在正在使用非wifi网络，继续播放将会产生流量费用")
    self.labNetWorkMention = [[UILabel alloc]init];
    [self.netWorkView addSubview:self.labNetWorkMention];
    
    [self.labNetWorkMention mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.netWorkView);
        make.height.mas_equalTo(@30);
    }];
    self.labNetWorkMention.textColor = C0;
    self.labNetWorkMention.numberOfLines = 0;
    self.labNetWorkMention.textAlignment = NSTextAlignmentCenter;
    self.labNetWorkMention.font = [UIFont systemFontOfSize:T5];
    self.labNetWorkMention.text = NetWork_Mention;

    
    //左边的按钮
    _btnLeft = [[UIButton alloc]init];
    [self.netWorkView addSubview:_btnLeft];
    
    [_btnLeft mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(@30);
        make.width.mas_equalTo(@60);
        make.top.mas_equalTo(self.labNetWorkMention.bottom).offset(10);
        make.left.mas_equalTo(self.labNetWorkMention).offset(-12);
    }];
    _btnLeft.backgroundColor = [UIColor clearColor];
    _btnLeft.tag = 0;
    _btnLeft.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _btnLeft.titleLabel.font = [UIFont systemFontOfSize: T5];
    [_btnLeft setTitleColor: C2 forState:UIControlStateNormal];
    [_btnLeft setTitle:@"停止播放" forState:UIControlStateNormal];
    [_btnLeft addTarget:self action:@selector(netWorkfResponce:) forControlEvents:UIControlEventTouchUpInside];

    
    //左边的按钮
    _btnRight = [[UIButton alloc]init];
    [self.netWorkView addSubview:_btnRight];
    
    [_btnRight mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(@30);
        make.width.mas_equalTo(@60);
        make.top.equalTo(self.labNetWorkMention.bottom).offset(10);
        make.right.equalTo(self.labNetWorkMention).offset(14);
    }];
    _btnRight.backgroundColor = [UIColor clearColor];
    _btnRight.tag = 1;
    _btnRight.titleLabel.font = [UIFont systemFontOfSize: T5];
    _btnRight.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_btnRight setTitleColor: C2 forState:UIControlStateNormal];
    [_btnRight setTitle:@"继续播放" forState:UIControlStateNormal];
    [_btnRight addTarget:self action:@selector(netWorkfResponce:) forControlEvents:UIControlEventTouchUpInside];

    
    //音量指示器
    _volumeView = [[DisplayerVolumeView alloc]init];
    [self addSubview:_volumeView];
    
    [_volumeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self).offset(ZCXHeightScale * 21);
        make.left.mas_equalTo(self).offset(ZCXWidthScale * 45);
        make.bottom.mas_equalTo(self).offset(-ZCXHeightScale * 24);
        make.width.mas_equalTo(ZCXWidthScale * 36);
    }];
    _volumeView.volumeImageView.image = [UIImage imageNamed:@"xiangqing_icon_sound"];
    _volumeView.hidden = YES;

    //获取当前系统音量
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];//创建单例对象并且使其设置为活跃状态.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:)   name:AVAudioSessionRouteChangeNotification object:nil];//设置通知
    
    //亮度调节指示器
    _brightnessView = [[DisplayerVolumeView alloc]init];
    [self addSubview:_brightnessView];
    
    [_brightnessView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self).offset(ZCXHeightScale * 21);
        make.right.mas_equalTo(self).offset(- ZCXWidthScale * 45);
        make.bottom.mas_equalTo(self).offset(- ZCXHeightScale * 24);
        make.width.mas_equalTo(ZCXWidthScale * 36);
    }];
    _brightnessView.volumeImageView.image = [UIImage imageNamed:@"xiangqing_icon_light"];
    
    
    [self setFastView];
    self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    self.singleTap.numberOfTapsRequired = 1; // 单击
    self.singleTap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:self.singleTap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appwillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    //关闭topview
    [self.topView setHidden:YES];
    self.netWorkView.hidden = YES;
    _brightnessView.hidden = YES;

}
//获取当前系统的音量
-(void)volumeChanged:(NSNotification *)notification{
    
    if (!self.isFullscreen && !self.isFromDetailView) {
        return;
    }
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    ZCXLog(@"FlyElephant-系统音量:%.1f", volume);
    
    _volumeView.hidden = NO;
    //外部修改，调整滑块
    _volumeView.volumeSlider.value = volume;
    [_volumeView setNumLabelText:volume AndFullOrSmall:_isFullscreen];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dbVolumeViewHidden) object:nil];
    [self performSelector:@selector(dbVolumeViewHidden) withObject:nil afterDelay:2.0];
}

-(void)dbVolumeViewHidden{
    self.volumeView.hidden = YES;
}


/**
 *耳机按钮的插入和拔除方法监听
 *
 *@param notification 通知方法
 */
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            ZCXLog(@"AVAudioSessionRouteChangeReasonNewDeviceAvailable");
            //tipWithMessage(@"耳机插入");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            ZCXLog(@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
            //tipWithMessage(@"耳机拔出，停止播放操作");
            [self play];
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            //tipWithMessage(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}
/**
 * 设置 autoLayout
 **/
-(void)makeConstraints{
    
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
    }];
    //[self.loadingView startAnimating];
    
    [self.btnPlayOrPause mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(100);
        make.width.mas_equalTo(100);
        make.center.mas_equalTo(self);
        
    }];
    
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self);
        make.right.mas_equalTo(self);
        make.height.mas_equalTo(60);
        make.top.mas_equalTo(self);
    }];
    
    [self.bgImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
        make.height.mas_equalTo(self);
        make.width.mas_equalTo(self);
    }];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self);
        make.right.mas_equalTo(self);
        make.height.mas_equalTo(40);
        make.bottom.mas_equalTo(self);
        
    }];
    
    
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.bottomView).offset(45);
        make.right.mas_equalTo(self.bottomView).offset(-80);
        make.centerY.mas_equalTo(self.bottomView);
        make.height.mas_equalTo(@3);
    }];
    
    //加载进度条
    [self.loadingProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.progressSlider);
        make.right.mas_equalTo(self.progressSlider);
        make.centerY.mas_equalTo(self.progressSlider);
        make.height.mas_equalTo(@1.0);
    }];
    [self.bottomView sendSubviewToBack:self.loadingProgress];
    
    //播放进度条screenSlider
    [self.screenSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self);
        make.right.mas_equalTo(self);
        make.bottom.mas_equalTo(self);
        make.height.mas_equalTo(@1.0);
    }];
    
    //缓存进度条
    [self.screenCacheSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.screenSlider);
        make.right.mas_equalTo(self.screenSlider);
        make.bottom.mas_equalTo(self.screenSlider);
        make.height.mas_equalTo(@1.0);
    }];
    
    //让子视图自动适应父视图的方法
    [self setAutoresizesSubviews:NO];
    
    [self.btnFullScreen mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.bottomView);
        make.height.mas_equalTo(40);
        make.bottom.mas_equalTo(self.bottomView);
        make.width.mas_equalTo(40);
    }];
    
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topView).offset(5);
        make.height.mas_equalTo(30);
        make.top.mas_equalTo(self.topView).offset(5);
        make.width.mas_equalTo(30);
    }];
    
    [self.leftTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.bottomView).offset(5);
        make.width.mas_equalTo(@35);
        make.height.mas_equalTo(@20);
        make.centerY.mas_equalTo(self.bottomView);
    }];
    
    [self.rightTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(@35);
        make.height.mas_equalTo(20);
        make.right.mas_equalTo(self.bottomView).offset(-35);
        make.centerY.mas_equalTo(self.bottomView).offset(0);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.topView).offset(12);
        make.right.mas_equalTo(self.topView).offset(-12);
        make.top.mas_equalTo(self.topView).offset(12);
    }];
    
    //[self.topView setHidden:YES];
    [self bringSubviewToFront:self.loadingView];
    [self bringSubviewToFront:self.btnPlayOrPause];
    [self bringSubviewToFront:self.bottomView];
    [self bringSubviewToFront:self.netWorkView];
    
}

//点击全片按钮
- (void) btnFilmDetail:(UIButton*)sender{
//    //全片点击事件 友盟数据埋点
//    NSDictionary *dict = @{@"EventID": UMeng_MobClick_ID_Film_Entry};
//    //点击刷新统计
//    [MobClick event:UMeng_MobClick_ID_Film_Entry attributes:dict];
    
    ZCXLog(@"全片按钮按钮被电击了！！！！！");
//    if (self.homePageCellDelegate && [self.homePageCellDelegate respondsToSelector:@selector(filmDetail:)]) {
//        [self.homePageCellDelegate filmDetail:_homePageModel];
//    }
}


#pragma mark - 重置播放器或销毁
/**
 * 重置播放器
 */
- (void)resetDisPlayer{
    self.currentItem = nil;
    self.seekTime = 0.0f;
    _URLString = nil;
    
    //self.screenShotImg = nil;
    self.progressSlider.value = 0.0;//指定初始值screenCacheSlider
    [self.loadingProgress setProgress:0.0 animated:NO];
    [self.screenCacheSlider setProgress:0.0 animated:NO];
    [self.screenSlider setProgress:0.0 animated:NO];
    [self.progressSlider setValue:0.0 animated:NO];
    
    [self.leftTimeLabel setText:@"00:00"];
    [self.rightTimeLabel setText:@"00:00"];
    // self.btnPlayOrPause = nil;
    // 暂停
    [self.player pause];
    // 移除原来的layer
    [self.playerLayer removeFromSuperlayer];
    // 替换PlayerItem为nil
    [self.player replaceCurrentItemWithPlayerItem:nil];
    // 把player置为nil
    self.playerLayer = nil;
    self.player = nil;
    
    self.backgroundColor = [UIColor clearColor];
    
    self.fastView.hidden = YES;
    [self.topView setHidden: YES];
    
}

/**
 * 关闭播放器
 */
-(void)closeDisPlayer{
    [self showSmallScreenWithPlayer:self];
    // 关闭定时器
    if ([self.autoDismissTimer isValid]) {
        [self.autoDismissTimer invalidate];
        self.autoDismissTimer = nil;
    }
    
    [self resetDisPlayer];
    self.topView.hidden = NO;
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [self.player pause];
    
    [self.player removeTimeObserver:self.playbackTimeObserver];
    
    //移除观察者
    [_currentItem removeObserver:self forKeyPath:@"status"];
    [_currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    _currentItem = nil;
    
    [self.autoDismissTimer invalidate];
    self.autoDismissTimer = nil;
    self.videoOutPut = nil;

}


#pragma mark --  移除播放器中的内容
-(void) removeDisPlayer{
    // 暂停
    [self.player pause];
    // 移除原来的layer
    [self.playerLayer removeFromSuperlayer];
    // 替换PlayerItem为nil
    [self.player replaceCurrentItemWithPlayerItem:nil];
    // 把player置为nil
    self.playerLayer = nil;
    self.player = nil;
}

#pragma mark -- 重新加载播放器内容
-(void) reLoadPlayer{
    if (_URLString) {
        //设置player的参数
        self.currentItem = [self getPlayItemWithURLString:_URLString];
        //添加输出流
        [self.currentItem addOutput: self.videoOutPut];
        
        self.player = [AVPlayer playerWithPlayerItem:_currentItem];
        self.player.usesExternalPlaybackWhileExternalScreenIsActive=YES;
        //AVPlayerLayer
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.frame = self.layer.bounds;
        //视频的默认填充模式，AVLayerVideoGravityResizeAspect
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.layer insertSublayer:_playerLayer atIndex:0];
        self.state = DBCHDisplayerStateBuffering;
    }
}

//释放内存空间
-(void)dealloc{
    ZCXLog(@"KYVedioPlayer dealloc");
    [self closeDisPlayer];
    
    //移除对应的监听方法
    [_hostReach stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - lazy 加载失败的label
-(UILabel *)loadFailedLabel{
    if (_labLoadFailed == nil) {
        _labLoadFailed = [[UILabel alloc]init];
        _labLoadFailed.textColor = [UIColor whiteColor];
        _labLoadFailed.textAlignment = NSTextAlignmentCenter;
        _labLoadFailed.text = @"视频加载失败";
        _labLoadFailed.hidden = YES;
        [self addSubview:_labLoadFailed];
        
        [_labLoadFailed mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(self);
            make.width.mas_equalTo(self);
            make.height.mas_equalTo(@30);
            
        }];
    }
    return _labLoadFailed;
}

#pragma mark -- lazy 网络切换提示语 按钮响应事件
- (void)netWorkfResponce: (UIButton*)sender{
    [self.netWorkView setHidden:YES];
    if (0 == sender.tag) {
        //取消播放
        NSUserDefaults* userDault = [NSUserDefaults standardUserDefaults];
        [userDault setObject:@"0" forKey:KNetWorkPlayer];
        [userDault synchronize];
        
        //[self resetDisPlayer];kyPlayerCancelPlayer
        if ([self.delegate respondsToSelector:@selector(kyPlayerCancelPlayer:)]) {
            //[self closeDisPlayer];
            [self.delegate kyPlayerCancelPlayer:self];
        }
        
    }else{
        //继续播放
        //[self reLoadPlayer];
        //self.is4GNetWork = NO;
        [self play];
        NSUserDefaults* userDault = [NSUserDefaults standardUserDefaults];
        [userDault setObject:@"1" forKey:KNetWorkPlayer];
        [userDault synchronize];
        
    }
}

#pragma mark  - 私有方法
/**
 * layoutSubviews
 **/
-(void)layoutSubviews{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}
/**
 * 获取视频长度
 **/
- (double)duration{
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        return CMTimeGetSeconds([[playerItem asset] duration]);
    }else{
        return 0.f;
    }
}
/**
 * 设置进度条的颜色
 **/
-(void)setProgressColor:(UIColor *)progressColor{
    
    if (progressColor == nil) {
        
        progressColor = [UIColor redColor];
    }
    if (self.progressSlider!=nil) {
        self.progressSlider.minimumTrackTintColor = progressColor;
    }
}
/**
 * 设置当前播放的时间
 **/
- (void)setCurrentTime:(double)time{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.player seekToTime:CMTimeMakeWithSeconds(time, self.currentItem.currentTime.timescale)];
        
    });
}

//设置视频总时长
-(void) setAllTime:(NSString *)allTime{
    self.rightTimeLabel.text = allTime;
}


/**
 重写播放器的尺寸和大小方法
 */
-(void)setDisPlayerFram:(CGRect)disPlayerFram{
    self.frame = disPlayerFram;
    [self makeConstraints];
}


/**
 *  重写URLString的setter方法，处理自己的逻辑，
 */
- (void)setURLString:(NSString *)URLString{
    self.isFullscreen = NO;
    self.isDragingSlider = NO;
    if (self.is4GNetWork && [[[NSUserDefaults standardUserDefaults] valueForKey:KNetWorkPlayer] isEqualToString:@"0"]) {
        [self.netWorkView setHidden:NO];
    }
    //同一个地址播放器内容不需要重置
    ZCXLog(@"URL :%@", _URLString);
    if (_URLString == URLString) {
        return;
    }

    //重置播放器
    [self resetDisPlayer];
    
    _URLString = URLString;
    //初始化输出流
    self.videoOutPut = [[AVPlayerItemVideoOutput alloc] init];
    //设置player的参数
    self.currentItem = [self getPlayItemWithURLString:URLString];
    //添加输出流
    [self.currentItem addOutput: self.videoOutPut];
    
    self.player = [AVPlayer playerWithPlayerItem:_currentItem];
    self.player.usesExternalPlaybackWhileExternalScreenIsActive = YES;
    //AVPlayerLayer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.layer.bounds;
    //视频的默认填充模式，AVLayerVideoGravityResizeAspect
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer insertSublayer:_playerLayer atIndex:0];
    self.state = DBCHDisplayerStateBuffering;
    
}

//重写homepageModel方法
- (void) setVedioModel:(VedioModel *)vedioModel{
    _vedioModel = vedioModel;
    
    //判断视频的清晰度
    //    _URLString = homePageModel.videoURL;
    NSString * url = vedioModel.videoURL;
    //wifi原画
    if (__GetWIFIDefinition && [__GetWIFIDefinition isEqualToString:@"1"]) {
        if (vedioModel.videoOriginal && vedioModel.videoOriginal.length > 0) {
            url = vedioModel.videoOriginal;
        }
    }
    
    //4G网络的时候
    if (self.is4GNetWork) {
        //判断选择的原画
        if (__GetWlanDefinition && [__GetWlanDefinition isEqualToString:@"1"]) {
            if (vedioModel.videoOriginal && vedioModel.videoOriginal.length > 0) {
                url = vedioModel.videoOriginal;
            }
        }
    }
    
    [self setURLString:url];
}

//重写isFromDetailView
-(void) setIsFromDetailView:(BOOL)isFromDetailView{
    _isFromDetailView = isFromDetailView;

}

/**
 *  判断是否是网络视频 还是 本地视频
 **/
-(AVPlayerItem *)getPlayItemWithURLString:(NSString *)url{
    if ([url containsString:@"http"]) {
        AVPlayerItem *playerItem=[AVPlayerItem playerItemWithURL:[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        return playerItem;
    }else{
        AVAsset *movieAsset  = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:url] options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        return playerItem;
    }
}

/**
 *  设置播放的状态
 *  @param state KYVedioPlayerState
 */
- (void)setState:(DBCHDisplayerState )state
{
    _state = state;
    // 控制菊花显示、隐藏
    if (DBCHDisplayerStateBuffering == state) {
        ZCXLog(@"开始菊花效果：%ld", state);
        [self.loadingView startAnimating];
        [self bringSubviewToFront:self.loadingView];
        
    }else if(DBCHDisplayerStatePlaying == state){
        [self.loadingView stopAnimating];
        
    }else if(DBCHDisplayerStatusReadyToPlay == state){
        [self.loadingView stopAnimating];
        
    }else{
        [self.loadingView stopAnimating];
    }
}
/**
 *  重写AVPlayerItem方法，处理自己的逻辑，
 */
-(void)setCurrentItem:(AVPlayerItem *)currentItem{
    if (_currentItem==currentItem) {
        return;
    }
    if (_currentItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
        [_currentItem removeObserver:self forKeyPath:@"status"];
        [_currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        _currentItem = nil;
    }
    _currentItem = currentItem;
    if (_currentItem) {
        [_currentItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionNew
                          context:PlayViewStatusObservationContext];
        
        [_currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        // 缓冲区空了，需要等待数据
        [_currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options: NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        // 缓冲区有足够数据可以播放了
        [_currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options: NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        
        
        [self.player replaceCurrentItemWithPlayerItem:_currentItem];
        // 添加视频播放结束通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
    }
}

#pragma mark - 播放 或者 暂停
- (void)PlayOrPause:(UIButton *)sender{
    if (self.player.rate != 1.f) {
        if ([self currentTime] == [self duration])
            [self setCurrentTime:0.f];
        sender.selected = NO;
        [self play];
    } else {
        sender.selected = YES;
        [self pause];
    }
    if ([self.delegate respondsToSelector:@selector(kyvedioPlayer:clickedPlayOrPauseButton:)]) {
        [self.delegate kyvedioPlayer:self clickedPlayOrPauseButton:sender];
    }
}

#pragma mark - 更新系统音量
- (void)updateSystemVolumeValue:(UISlider *)slider{
    self.systemSlider.value = slider.value;
}
#pragma mark - 进度条的相关事件 progressSlider
/**
 *   开始点击sidle
 **/
- (void)stratDragSlide:(UISlider *)slider{
    self.seekTime = 0.0f;
    self.isDragingSlider = YES;
    //self.isDragingSlider = NO;
    
}
/**
 *   更新播放进度
 **/
- (void)updateProgress:(UISlider *)slider{
    //self.isDragingSlider = NO;
    [self.player seekToTime:CMTimeMakeWithSeconds(slider.value, _currentItem.currentTime.timescale)];
    self.isDragingSlider = NO;
}
/**
 *  视频进度条的点击事件
 **/
- (void)actionTapGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchLocation = [sender locationInView:self.progressSlider];
    CGFloat value = (self.progressSlider.maximumValue - self.progressSlider.minimumValue) * (touchLocation.x/self.progressSlider.frame.size.width);
    
    [self.progressSlider setValue:value animated:YES];
    [self.screenSlider setProgress:self.progressSlider.value/self.progressSlider.maximumValue animated:YES];
    self.screenSlider.progressTintColor = C2;
    [self.player seekToTime:CMTimeMakeWithSeconds(self.progressSlider.value, self.currentItem.currentTime.timescale)];
    if (self.player.rate != 1.f) {
        if ([self currentTime] == [self duration])
            [self setCurrentTime:0.f];
        self.btnPlayOrPause.selected = NO;
        [self.player play];
    }
}

#pragma mark -- 是否全屏
- (void) setIsForbiddenFullScreen:(BOOL)isForbiddenFullScreen{
    //self.isForbiddenFullScreen = isForbiddenFullScreen;
    if (!isForbiddenFullScreen) {
        [self.btnFullScreen setEnabled:NO];
        //隐藏全屏按钮
        [self.btnFullScreen setImage:nil forState:UIControlStateNormal];
        [self.btnFullScreen setImage:nil forState:UIControlStateSelected];
        [self.bottomView addSubview:self.btnFullScreen];
        
    }else{
        [self.btnFullScreen setEnabled:YES];
        [self.btnFullScreen setImage:[UIImage imageNamed:@"full_icon"] ?: [UIImage imageNamed:@"full_icon"] forState:UIControlStateNormal];
        [self.btnFullScreen setImage:[UIImage imageNamed:@"Exit full screen_icon"] ?: [UIImage imageNamed:@"Exit full screen_icon"] forState:UIControlStateSelected];
        [self.bottomView addSubview:self.btnFullScreen];
        
    }
    
}

#pragma mark  -  点击全屏按钮 和 点击缩小按钮
/**
 *   点击全屏按钮 和 点击缩小按钮
 **/
-(void)fullScreenAction:(UIButton *)sender{
    sender.selected = !sender.selected;
    if (sender.selected) {
        _isFromHomePage = YES;
    }else{
        _isFromHomePage = NO;
    }
    
    self.closeBtn.selected = sender.selected;
    [self.closeBtn setHidden:!sender.selected];
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(kyvedioPlayer:clickedFullScreenButton:)]) {
        [self.delegate kyvedioPlayer:self clickedFullScreenButton:sender];
    }
}

#pragma mark - 点击关闭按钮
/**
 *   点击关闭按钮
 **/
-(void)colseTheVideo:(UIButton *)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(kyvedioPlayer:clickedCloseButton:)]) {
        [self.delegate kyvedioPlayer:self clickedCloseButton:sender];
    }
}
#pragma mark - 单击播放器 手势方法
- (void)handleSingleTap:(UITapGestureRecognizer *)sender{
    // [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoDismissBottomView:) object:nil];
    if (self.delegate&&[self.delegate respondsToSelector:@selector(kyvedioPlayer:singleTaped:)]) {
        [self.delegate kyvedioPlayer:self singleTaped:sender];
    }
    if (_isAutoDismissBottomView == YES) {  //每3秒 自动隐藏底部视图
        if ([self.autoDismissTimer isValid]) {
            [self.autoDismissTimer invalidate];
            self.autoDismissTimer = nil;
        }
        self.autoDismissTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
    }
    
    if (self.bottomView.alpha == 0.0) {
        self.bottomView.alpha = 1.0;
        self.btnPlayOrPause.alpha = 1.0;
        self.topView.alpha = 1.0;
        self.bgImgView.alpha = 1.0;
        self.screenSlider.alpha  = 0.0;
        self.screenCacheSlider.alpha = 0.0;
    }else{
        self.bottomView.alpha = 0.0;
        //self.btnClose.alpha = 0.0;
        self.btnPlayOrPause.alpha = 0.0;
        self.topView.alpha = 0.0;
        self.bgImgView.alpha = 0.0;
        
        self.screenSlider.alpha  = 1.0;
        self.screenCacheSlider.alpha = 1.0;
    }
}

/**
 * 隐藏 底部视图
 **/
-(void)autoDismissBottomView:(NSTimer *)timer{
    
    if (self.player.rate==.0f&&self.currentTime != self.duration) {//暂停状态
        
    }else if(self.player.rate == 1.0f){
        if ((1.0 == self.btnPlayOrPause.alpha)|| (1.0 == self.bottomView.alpha)) {
            [UIView animateWithDuration:0.5 animations:^{
                self.bottomView.alpha = 0.0;
                self.btnPlayOrPause.alpha = 0.0;
                self.topView.alpha = 0.0;
                self.bgImgView.alpha = 0.0;
                
                self.screenSlider.alpha  = 1.0;
                self.screenCacheSlider.alpha = 1.0;
            } completion:^(BOOL finish){
                
            }];
        }
    }
}
#pragma mark - 双击播放器 手势方法
- (void)handleDoubleTap:(UITapGestureRecognizer *)doubleTap{
    if (self.delegate&&[self.delegate respondsToSelector:@selector(kyvedioPlayer:doubleTaped:)]) {
        [self.delegate kyvedioPlayer:self doubleTaped:doubleTap];
    }
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomView.alpha = 1.0;
        self.topView.alpha = 1.0;
        self.bgImgView.alpha = 1.0;
        self.btnPlayOrPause.alpha = 1.0;
        
    } completion:^(BOOL finish){
        self.screenSlider.alpha  = 0.0;
        self.screenCacheSlider.alpha = 0.0;
    }];
}


#pragma mark - NSNotification 消息通知接收
/**
 *  接收播放完成的通知
 **/
- (void)moviePlayDidEnd:(NSNotification *)notification {
    self.state = DBCHDisplayerStateFinished;
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [self.progressSlider setValue:0.0 animated:YES];
        [self.screenSlider setProgress:0.0 animated:YES];
        //self.btnPlayOrPause.selected = YES;
    }];
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomView.alpha = 1.0;
        self.topView.alpha = 1.0;
        self.bgImgView.alpha = 1.0;
        
    } completion:^(BOOL finish){
        self.screenSlider.alpha  = 0.0;
        self.screenCacheSlider.alpha = 0.0;
    }];
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(kyplayerFinishedPlay:)]) {
        [self.delegate kyplayerFinishedPlay:self];
    }
}

- (void)appwillResignActive:(NSNotification *)note{
    ZCXLog(@"appwillResignActive");
}

- (void)appBecomeActive:(NSNotification *)note{
    ZCXLog(@"appBecomeActive");
}
/**
 * 进入后台
 **/
- (void)appDidEnterBackground:(NSNotification*)note{
}

/**
 *  进入前台
 **/
- (void)appWillEnterForeground:(NSNotification*)note{
    //不是暂停的时候，继续播放
    if (!self.btnPlayOrPause.isSelected) {
        [self play];
    }
}


#pragma mark - 对外方法
/**
 *  播放
 */
- (void)play{
    if ([self currentTime] == [self duration])
        [self setCurrentTime:0.f];
    self.btnPlayOrPause.selected = NO;
    //是否显示底部view
    if (0.0 == self.bottomView.alpha) {
        self.btnPlayOrPause.alpha = 0.0;
    }
    self.detailState = DBCHDisplayerStatePlaying;
    [self.player play];
    
    if ([self.delegate respondsToSelector:@selector(kyvedioPlayer:clickedPlayOrPauseButton:)]) {
        [self.delegate kyvedioPlayer:self clickedPlayOrPauseButton:self.btnPlayOrPause];
    }
    
    if (_isAutoDismissBottomView == YES) {  //每3秒 自动隐藏底部视图
        if ([self.autoDismissTimer isValid]) {
            [self.autoDismissTimer invalidate];
            self.autoDismissTimer = nil;
        }
        self.autoDismissTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
    }
}

/**
 * 暂停
 */
- (void)pause{
    self.btnPlayOrPause.selected = YES;
    self.btnPlayOrPause.alpha = 1.0;
    self.detailState = DBCHDisplayerStateStopped;
    [self.player pause];
    if ([self.delegate respondsToSelector:@selector(kyvedioPlayer:clickedPlayOrPauseButton:)]) {
        [self.delegate kyvedioPlayer:self clickedPlayOrPauseButton:self.btnPlayOrPause];
    }
}

/**
 * 是否正在播放中
 * @return BOOL YES 正在播放 NO 不在播放中
 **/
- (BOOL)isPlaying {
    if (_player && _player.rate != 0) {
        return YES;
    }
    return NO;
}
/**
 *  获取正在播放的时间点
 *
 *  @return double的一个时间点
 */
- (double)currentTime{
    if (self.player) {
        return CMTimeGetSeconds([self.player currentTime]);
    }else{
        return 0.0;
    }
}

#pragma mark - KVO 监听
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    /* AVPlayerItem "status" property value observer. */
    if (context == PlayViewStatusObservationContext)
    {
        if ([keyPath isEqualToString:@"status"]) {
            AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            switch (status)
            {
                    /* Indicates that the status of the player is not yet known because
                     it has not tried to load new media resources for playback */
                case AVPlayerStatusUnknown:
                {
                    [self.loadingProgress setProgress:0.0 animated:NO];
                    [self.screenCacheSlider setProgress:0.0 animated:NO];
                    self.state = DBCHDisplayerStateBuffering;
                    //[self.loadingView startAnimating];
                }
                    break;
                    
                case AVPlayerStatusReadyToPlay:
                {
                    self.state = DBCHDisplayerStatusReadyToPlay;
                    
                    // 双击的 Recognizer
                    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
                    doubleTap.numberOfTapsRequired = 2; // 双击
                    [self.singleTap requireGestureRecognizerToFail:doubleTap];//如果双击成立，则取消单击手势（双击的时候不回走单击事件）
                    [self addGestureRecognizer:doubleTap];
                    
                    // 加载完成后，再添加平移手势
                    // 添加平移手势，用来控制音量、亮度、快进快退
                    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
                    panRecognizer.delegate = self;
                    [panRecognizer setMaximumNumberOfTouches:1];
                    [panRecognizer setDelaysTouchesBegan:YES];
                    [panRecognizer setDelaysTouchesEnded:YES];
                    [panRecognizer setCancelsTouchesInView:YES];
                    [self addGestureRecognizer:panRecognizer];
                    
                    /* Once the AVPlayerItem becomes ready to play, i.e.
                     [playerItem status] == AVPlayerItemStatusReadyToPlay,
                     its duration can be fetched from the item. */
                    ZCXLog(@"开始加载时间：");
                    double _x = CMTimeGetSeconds(_currentItem.duration);
                    
                    ZCXLog(@"开始加载结束：");
                    self.progressSlider.maximumValue = _x;
                    /*if (_x) {
                     if (!isnan(_x)) {
                     self.progressSlider.maximumValue = _x;//CMTimeGetSeconds(self.player.currentItem.duration);
                     }
                     }*/
                    
                    [self initTimer];
                    
                    if (_isAutoDismissBottomView == YES) {  //每5秒 自动隐藏底部视图
                        if (self.autoDismissTimer==nil) {
                            self.autoDismissTimer = [NSTimer timerWithTimeInterval: 3.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
                            [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
                        }
                    }
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(kyvedioPlayerReadyToPlay:playerStatus:)]) {
                        [self.delegate kyvedioPlayerReadyToPlay:self playerStatus:DBCHDisplayerStatusReadyToPlay];
                    }
                    //[self.loadingView stopAnimating];
                    // 跳到xx秒播放视频
                    if (0 != self.seekTime) {
                        [self seekToTimeToPlay:self.seekTime];
                        self.seekTime = 0.0f;
                    }
                }
                    break;
                    
                case AVPlayerStatusFailed:
                {
                    self.state = DBCHDisplayerStateFailed;
                    if (self.delegate&&[self.delegate respondsToSelector:@selector(kyvedioPlayerFailedPlay:playerStatus:)]) {
                        NSError *error = [self.player.currentItem error];
                        if (error) {
                            self.loadFailedLabel.hidden = NO;
                            [self bringSubviewToFront:self.loadFailedLabel];
                            //[self.loadingView stopAnimating];
                        }
                        ZCXLog(@"视频加载失败===%@",error.description);
                        [self.delegate kyvedioPlayerFailedPlay:self playerStatus:DBCHDisplayerStateFailed];
                    }
                }
                    break;
            }
            
        }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            
            // 计算缓冲进度
            NSTimeInterval timeInterval = [self availableDuration];
            CMTime duration             = self.currentItem.duration;
            CGFloat totalDuration       = CMTimeGetSeconds(duration);
            //缓冲颜色
            self.loadingProgress.progressTintColor = ZCXColor(255, 255, 255, 0.7);
            [self.loadingProgress setProgress: timeInterval/totalDuration animated: NO];
            
            //缓冲颜色
            self.screenCacheSlider.progressTintColor = ZCXColor(255, 255, 255, 0.7);
            [self.screenCacheSlider setProgress: timeInterval/totalDuration animated: NO];
            
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            //[self.loadingView startAnimating];
            // 当缓冲是空的时候
            if (self.currentItem.playbackBufferEmpty) {
                if (self.player.rate <= 0) {
                    [self loadedTimeRanges];
                }else{
                    self.state = DBCHDisplayerStateBuffering;
                }
            }
            
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            //[self.loadingView stopAnimating];
            // 当缓冲好的时候
            if (self.currentItem.playbackLikelyToKeepUp && self.state == DBCHDisplayerStateBuffering){
                self.state = DBCHDisplayerStatePlaying;
            }
        }
    }
}

#pragma mark - UIPanGestureRecognizer手势方法

/**
 *  pan手势事件
 *
 *  @param pan UIPanGestureRecognizer
 */
- (void)panDirection:(UIPanGestureRecognizer *)pan
{
    //根据在view上Pan的位置，确定是调音量还是亮度
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    self.lightSlider.value = [UIScreen mainScreen].brightness;
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            CGPoint locationPoint = [pan locationInView:self];
            self.firstPoint = locationPoint;
            self.volumeSlider.value = self.systemSlider.value;
            //记录下第一个点的位置,用于moved方法判断用户是调节音量还是调节视频
            self.originalPoint = self.firstPoint;
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                // 取消隐藏
                self.panDirection = PanDirectionHorizontalMoved;
                // 给sumTime初值
                CMTime time       = self.player.currentTime;
                self.sumTime      = time.value/time.timescale;
            }
            else if (x < y){ // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            CGPoint locationPoint = [pan locationInView:self];
            self.secondPoint = locationPoint;
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved:{
                    if (self.isFullscreen) {//全屏下
                        //判断刚开始的点是左边还是右边,左边控制音量
                        if (self.originalPoint.x > kHalfHeight) {//全屏下:point在view的右边(控制音量)
                            
                            /*手指上下移动的计算方式,根据y值,刚开始进度条在0位置,当手指向上移动600个点后,当手指向上移动N个点的距离后,
                             当前的进度条的值就是N/600,600随开发者任意调整,数值越大,那么进度条到大1这个峰值需要移动的距离也变大,反之越小*/
                            //                            self.systemSlider.value += (self.firstPoint.y - self.secondPoint.y)/600.0;
                            self.systemSlider.value += (self.firstPoint.y - self.secondPoint.y)/SCREEN_WIDTH * 1.0 * 1.6;
                            self.volumeSlider.value = self.systemSlider.value;
                            
                            _volumeView.hidden = NO;
                            _volumeView.volumeSlider.value = _systemSlider.value;
                            [_volumeView setNumLabelText:_systemSlider.value AndFullOrSmall:_isFullscreen];
                            
                        }else{//全屏下:point在view的左边(控制亮度)
                            //右边调节屏幕亮度
                            //                            self.lightSlider.value += (self.firstPoint.y - self.secondPoint.y)/600.0;
                            self.lightSlider.value += (self.firstPoint.y - self.secondPoint.y) / SCREEN_WIDTH * 1.0 *1.6;
                            self.brightnessView.hidden = NO;
                            _brightnessView.volumeSlider.value = self.lightSlider.value;
                            
                            [[UIScreen mainScreen] setBrightness:self.lightSlider.value];
                            
                        }
                    }else{//非全屏
                        
                        //判断刚开始的点是左边还是右边,左边控制音量
                        if (self.originalPoint.x > kHalfWidth) {//非全屏下:point在view的右边(控制音量)
                            
                            /* 手指上下移动的计算方式,根据y值,刚开始进度条在0位置,当手指向上移动600个点后,当手指向上移动N个点的距离后,
                             当前的进度条的值就是N/600,600随开发者任意调整,数值越大,那么进度条到大1这个峰值需要移动的距离也变大,反之越小 */
                            //                            _systemSlider.value += (self.firstPoint.y - self.secondPoint.y)/600.0;
                            _systemSlider.value += (self.firstPoint.y - self.secondPoint.y)/SCREEN_HEIGHT * 1.0 * 1.6;
                            self.volumeSlider.value = _systemSlider.value;
                            
                            _volumeView.hidden = NO;
                            _volumeView.volumeSlider.value = _systemSlider.value;
                            
                            [_volumeView setNumLabelText:_systemSlider.value AndFullOrSmall:_isFullscreen];
                            
                        }else{//非全屏下:point在view的左边(控制亮度)
                            //右边调节屏幕亮度
                            //                            self.lightSlider.value += (self.firstPoint.y - self.secondPoint.y)/600.0;
                            self.lightSlider.value += (self.firstPoint.y - self.secondPoint.y) / SCREEN_HEIGHT * 1.0 *1.6;
                            self.brightnessView.hidden = NO;
                            _brightnessView.volumeSlider.value = self.lightSlider.value;
                            
                            [[UIScreen mainScreen] setBrightness:self.lightSlider.value];
                            
                        }
                    }
                    self.firstPoint = self.secondPoint;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    self.fastView.hidden = YES;
                    [self seekToTime:self.sumTime completionHandler:nil];
                    // 把sumTime滞空，不然会越加越多
                    self.sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    
                    //取消任务
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(viewHidden) object:nil];
                    //延迟执行
                    [self performSelector:@selector(viewHidden) withObject:nil afterDelay:0.3];
                    
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.firstPoint = self.secondPoint = CGPointZero;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

-(void)viewHidden{
    self.volumeView.hidden = YES;
    self.brightnessView.hidden = YES;
}


/**
 *  从xx秒开始播放视频跳转
 *
 *  @param dragedSeconds 视频跳转的秒数
 */
- (void)seekToTime:(NSInteger)dragedSeconds completionHandler:(void (^)(BOOL finished))completionHandler
{
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        // seekTime:completionHandler:不能精确定位
        // 如果需要精确定位，可以使用seekToTime:toleranceBefore:toleranceAfter:completionHandler:
        // 转换成CMTime才能给player来控制播放进度
        //        [self.controlView zf_playerActivity:YES];
        [self.player pause];
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1); //kCMTimeZero
        __weak typeof(self) weakSelf = self;
        [self.player seekToTime:dragedCMTime toleranceBefore:CMTimeMake(1,1) toleranceAfter:CMTimeMake(1,1) completionHandler:^(BOOL finished) {
            // 视频跳转回调
            if (completionHandler) { completionHandler(finished); }
            [weakSelf.player play];
            weakSelf.seekTime = 0;
            weakSelf.isDragged = NO;
            // 结束滑动
            //            [weakSelf db_playerDraggedEnd];
        }];
    }
}

- (void)db_playerDraggedEnd{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.fastView.hidden = YES;
    });
}


/**
 *  pan水平移动的方法
 *
 *  @param value void
 */
- (void)horizontalMoved:(CGFloat)value
{
    CMTime totalTime           = self.currentItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    // 每次滑动需要叠加时间
    if (_isFullscreen) {
        self.sumTime += value / self.frame.size.height * totalMovieDuration / 60 * 0.5;
    }else{
        self.sumTime += value / self.frame.size.width * totalMovieDuration / 60 * 0.5;
    }
    
    // 需要限定sumTime的范围
    if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
    if (self.sumTime < 0) { self.sumTime = 0; }
    
    BOOL style = false;
    if (value > 0) { style = YES; }
    if (value < 0) { style = NO; }
    if (value == 0) { return; }
    
    self.isDragged = YES;
    [self db_playerDraggedTime:self.sumTime totalTime:totalMovieDuration isForward:style hasPreview:NO];
}
- (void)db_playerDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd hasPreview:(BOOL)preview{
    // 拖拽的时长
    NSInteger proMin = draggedTime / 60;//当前秒
    NSInteger proSec = draggedTime % 60;//当前分钟
    
    //duration 总时长
    NSInteger durMin = totalTime / 60;//总秒
    NSInteger durSec = totalTime % 60;//总分钟
    
    NSString *currentTimeStr = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    NSString *totalTimeStr   = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
    CGFloat  draggedValue    = (CGFloat)draggedTime/(CGFloat)totalTime;
    float maxValue = [self.progressSlider maximumValue];
    [self.progressSlider setValue:draggedValue * maxValue animated:YES];
    [self.screenSlider setProgress:self.progressSlider.value/self.progressSlider.maximumValue animated:YES];
    if (forawrd) {
        self.fastImageView.image = [UIImage imageNamed:@"xiangqing_icon_kuaijin"];
    } else {
        self.fastImageView.image = [UIImage imageNamed:@"xiangqing_icon_houtui"];
    }
    self.fastView.hidden           = preview;
    self.fastTimeLabel.text        = currentTimeStr;
    self.allTimeLabel.text         = [NSString stringWithFormat:@" / %@",totalTimeStr];
    self.fastProgressView.progress = draggedValue;
}

- (void)setFastView{
    [self addSubview:self.fastView];
    self.fastView.hidden = YES;
    [self.fastView addSubview:self.fastImageView];
    [self.fastView addSubview:self.fastTimeLabel];
    [self.fastView addSubview:self.allTimeLabel];
    [self.fastView addSubview:self.fastProgressView];
    
    [self.fastView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(177);
        make.height.mas_equalTo(78);
        make.top.mas_equalTo(self).offset(9);
        make.centerX.mas_equalTo(self);
    }];
    
    [self.fastImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(@24);
        make.height.mas_equalTo(@24);
        make.top.mas_equalTo(9);
        make.centerX.mas_equalTo(self.fastView);
    }];
    
    [self.fastTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(0);
        make.trailing.equalTo(self.fastImageView.leading);
        make.top.mas_equalTo(self.fastImageView.mas_bottom).offset(5);
    }];
    
    [self.allTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(0);
        make.leading.equalTo(self.fastTimeLabel.trailing);
        make.top.mas_equalTo(self.fastImageView.mas_bottom).offset(5);
    }];
    
    [self.fastProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(10);
        make.trailing.mas_equalTo(-10);
        make.height.mas_equalTo(@3);
        make.bottom.mas_equalTo(self.fastView).offset(-9);
    }];
}

- (UIProgressView *)fastProgressView
{
    if (!_fastProgressView) {
        _fastProgressView                   = [[UIProgressView alloc] init];
        _fastProgressView.progressTintColor = C2;
        _fastProgressView.trackTintColor    = RGBCOLOR(142, 141, 140);
    }
    return _fastProgressView;
}

- (UILabel *)fastTimeLabel
{
    if (!_fastTimeLabel) {
        _fastTimeLabel               = [[UILabel alloc] init];
        _fastTimeLabel.textColor     = C2;
        _fastTimeLabel.textAlignment = NSTextAlignmentRight;
        _fastTimeLabel.font          = [UIFont systemFontOfSize:T1_2];
    }
    return _fastTimeLabel;
}

- (UILabel *)allTimeLabel
{
    if (!_allTimeLabel) {
        _allTimeLabel               = [[UILabel alloc] init];
        _allTimeLabel.textColor     = [UIColor whiteColor];
        _allTimeLabel.textAlignment = NSTextAlignmentLeft;
        _allTimeLabel.font          = [UIFont systemFontOfSize:T1_2];
    }
    return _allTimeLabel;
}

- (UIView *)fastView
{
    if (!_fastView) {
        _fastView                     = [[UIView alloc] init];
        _fastView.backgroundColor     = C1_2;
        _fastView.layer.cornerRadius  = 4;
        _fastView.layer.masksToBounds = YES;
    }
    return _fastView;
}

- (UIImageView *)fastImageView
{
    if (!_fastImageView) {
        _fastImageView = [[UIImageView alloc] init];
    }
    return _fastImageView;
}

-(AVAssetImageGenerator*) imgGenerator{
    if (!_imgGenerator) {
        _imgGenerator = [[AVAssetImageGenerator alloc]initWithAsset:_currentItem.asset];
    }
    return _imgGenerator;
}

/**
 *  防止UISlide跟拖拽手势冲突
 */
-(BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
    
    
    if (_isFromDetailView == YES) {
        return YES;
    }else{
        if (_isFromHomePage == YES) {
            if([touch.view isKindOfClass:[UISlider class]])
            {
                if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
                    return NO;
                }else{
                    return YES;
                }
            }else{
                return YES;
            }
        }else{
            if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
                return NO;
            }else{
                return YES;
            }
            
        }
    }
}

/**
 * 重置全屏按钮的设置方法
 */
-(void) setIsFullscreen:(BOOL)isFullscreen{
    _isFullscreen = isFullscreen;
    //全屏的时候
    if (_isFullscreen) {
        //关闭音量
        [self addSubview:_mpVolumeView];
        [_mpVolumeView sizeToFit];
        
    }else{
        //显示系统音量调节方式
        if (_isFromDetailView) {
            //关闭音量
            [self addSubview:_mpVolumeView];
            [_mpVolumeView sizeToFit];
        }else{
            //显示系统音量
            [_mpVolumeView removeFromSuperview];
        }
    }
}


/**
 *  缓冲回调
 */
- (void)loadedTimeRanges
{
    self.state = DBCHDisplayerStateBuffering;
}
#pragma  mark - 定时器 监听播放状态
-(void)initTimer{
    double interval = .1f;
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)){
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    
    double _x = duration;//CMTimeGetSeconds(_currentItem.duration);
    if (_x) {
        if (!isnan(_x)) {
            self.progressSlider.maximumValue = _x;//CMTimeGetSeconds(self.player.currentItem.duration);
        }
    }
    
    if (isfinite(duration))
    {
        CGFloat width = CGRectGetWidth([self.progressSlider bounds]);
        interval = 0.5f * duration / width;
    }
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver =  [weakSelf.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0, NSEC_PER_SEC)  queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
        [weakSelf syncScrubber];
    }];
}
- (void)syncScrubber{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)){
        self.progressSlider.minimumValue = 0.0;
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)){
        float minValue = [self.progressSlider minimumValue];
        float maxValue = [self.progressSlider maximumValue];
        double nowTime = CMTimeGetSeconds([self.player currentTime]);
        double remainTime = duration-nowTime;
        if (nowTime > 0) {
            self.backgroundColor = [UIColor blackColor];
        }
        self.leftTimeLabel.text = [self convertTime:nowTime];
        self.rightTimeLabel.text = [self convertTime:duration];
        
        if (self.isDragingSlider == YES) {//拖拽slider中，不更新slider的值
            self.isDragingSlider = NO;
            
        }else if(NO == self.isDragingSlider){
            [self.progressSlider setValue:(maxValue - minValue) * nowTime / duration + minValue];
            [self.screenSlider setProgress:self.progressSlider.value/self.progressSlider.maximumValue animated:YES];
            self.screenSlider.progressTintColor = C2;
        }
        
    }
    
    //self.isDragingSlider = NO;
}
/**
 *  跳到time处播放
 *  seekTime这个时刻，这个时间点
 */
- (void)seekToTimeToPlay:(double)time{
    if (self.player&&self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        if (time>[self duration]) {
            time = [self duration];
        }
        if (time<=0) {
            time=0.0;
        }
        //        int32_t timeScale = self.player.currentItem.asset.duration.timescale;
        //currentItem.asset.duration.timescale计算的时候严重堵塞主线程，慎用
        /* A timescale of 1 means you can only specify whole seconds to seek to. The timescale is the number of parts per second. Use 600 for video, as Apple recommends, since it is a product of the common video frame rates like 50, 60, 25 and 24 frames per second*/
        
        [self.player seekToTime:CMTimeMakeWithSeconds(time, _currentItem.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            
        }];
        
        
    }
}
- (CMTime)playerItemDuration{
    AVPlayerItem *playerItem = _currentItem;
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        return([playerItem duration]);
    }
    return(kCMTimeInvalid);
}
/**
 * 把秒转换成格式
 **/
- (NSString *)convertTime:(CGFloat)second{
    if (second < 0) {
        return @"00:00";
    }
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *newTime = [[self dateFormatter] stringFromDate:d];
    return newTime;
}
/**
 *  计算缓冲进度
 *
 *  @return 缓冲进度
 */
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [_currentItem loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}
/**
 * 时间转换格式
 **/
- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}
#pragma mark - 全屏显示播放 和 缩小显示播放器
/**
 *  全屏显示播放
 ＊ @param interfaceOrientation 方向
 ＊ @param player 当前播放器
 ＊ @param fatherView 当前父视图
 **/
-(void)showFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation player:(DisplayerView *)player withFatherView:(UIView *)fatherView{
    [player removeFromSuperview];
    player.transform = CGAffineTransformIdentity;
    if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
        player.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
        player.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    player.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    player.backgroundColor = C1;
    player.playerLayer.frame =  CGRectMake(0, 0, SCREEN_HEIGHT,  SCREEN_WIDTH);
    
    [player.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.bottom.mas_equalTo(-40);
        make.left.mas_equalTo(player);
        make.right.mas_equalTo(player);
    }];
    [player.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(player);
        make.height.mas_equalTo(60);
        make.left.mas_equalTo(player);
        make.width.mas_equalTo(SCREEN_HEIGHT);
    }];
    
    [player.bgImgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(SCREEN_HEIGHT);
        make.top.mas_equalTo(player);
        make.left.mas_equalTo(player);
        make.height.mas_equalTo(SCREEN_WIDTH);
    }];
    
    [player.btnPlayOrPause mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self);
        make.centerY.mas_equalTo(self);
        make.height.mas_equalTo(@180);
        make.width.mas_equalTo(@180);
    }];
    
    [player.fastView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(player);
        make.height.mas_equalTo(@78);
        make.width.mas_equalTo(@336);
        make.top.mas_equalTo(player).offset(18);
    }];
    
    
    [player.fastProgressView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(27);
        make.trailing.mas_equalTo(-27);
        make.height.mas_equalTo(@3);
        make.bottom.mas_equalTo(player.fastView).offset(-9);
    }];
    
    [player.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(player.topView).offset(45);
        make.right.mas_equalTo(player.topView).offset(-45);
        make.top.mas_equalTo(player.topView).offset(20);
    }];
    
    [player.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(player.topView).offset(5);
        make.height.mas_equalTo(@30);
        make.centerY.mas_equalTo(player.titleLabel);
        make.width.mas_equalTo(@30);
    }];
    
    [player.loadFailedLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(SCREEN_HEIGHT);
        make.center.mas_equalTo(CGPointMake(SCREEN_WIDTH/2-36, -(SCREEN_WIDTH/2)+36));
        make.height.mas_equalTo(@30);
    }];
    [player.loadingView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(CGPointMake(SCREEN_WIDTH/2-37, -(SCREEN_WIDTH/2-37)));
    }];
    
    //设置对应的4G提示框显示内容
    [player.netWorkView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(SCREEN_HEIGHT);
        make.height.mas_equalTo(SCREEN_WIDTH);
        make.top.mas_equalTo(0);
    }];
    
    
    [player.volumeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(player).offset(ZCXHeightScale * 21);
        make.height.mas_equalTo(ZCXWidthScale * 192);
        make.width.mas_equalTo(ZCXHeightScale * 48);
        make.top.mas_equalTo(player).offset((SCREEN_WIDTH - ZCXWidthScale *192)/2);
    }];
    
    [player.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(player).offset(- ZCXHeightScale * 21);
        make.height.mas_equalTo(ZCXWidthScale * 192);
        make.width.mas_equalTo(ZCXHeightScale * 48);
        make.top.mas_equalTo(player).offset((SCREEN_WIDTH - ZCXWidthScale *192)/2);
    }];
    
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    [_volumeView fullOrSmall:YES];
    [_brightnessView fullOrSmall:YES];
    [_brightnessView setImage:YES];
    
    [fatherView addSubview:player];
    player.btnFullScreen.selected = YES;
    //换上大图
    [player.btnPlayOrPause setImage:[UIImage imageNamed:@"pause_fullscreen_btn"] ?: [UIImage imageNamed:@"pause_fullscreen_btn"] forState:UIControlStateNormal];
    [player.btnPlayOrPause setImage:[UIImage imageNamed:@"play_fullscreen_btn"] ?: [UIImage imageNamed:@"play_fullscreen_btn"] forState:UIControlStateSelected];
    
    [player bringSubviewToFront:player.bgImgView];
    [player bringSubviewToFront:player.topView];
    [player bringSubviewToFront:player.bottomView];
    [player bringSubviewToFront:player.netWorkView];
    [player.topView setHidden:NO];
    
}

/**
 *  小屏幕显示播放
 ＊ @param player 当前播放器
 ＊ @param fatherView 当前父视图
 ＊ @param playerFrame 小屏幕的Frame
 **/
-(void)showSmallScreenWithPlayer:(DisplayerView *)player withFatherView:(UIView *)fatherView withFrame:(CGRect )playerFrame{
    [player removeFromSuperview];
    [UIView animateWithDuration:0.5f animations:^{
        player.transform = CGAffineTransformIdentity;
        player.frame = CGRectMake(playerFrame.origin.x, playerFrame.origin.y, playerFrame.size.width, playerFrame.size.height);
        player.playerLayer.frame =  player.bounds;
        [fatherView addSubview:player];
        [player.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(player);
            make.right.equalTo(player);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(player);
        }];
        
        [player.btnPlayOrPause mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(player);
            make.height.mas_equalTo(@100);
            make.width.mas_equalTo(@100);
        }];
        
        [player.fastView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(177);
            make.height.mas_equalTo(80);
            make.top.mas_equalTo(player).offset(9);
            make.centerX.mas_equalTo(player);
        }];
        
        [player.fastProgressView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(player);
            make.height.mas_equalTo(3);
            make.width.mas_equalTo(146);
            make.bottom.mas_equalTo(player.fastView.bottom).offset(-9);
        }];
        
        [player.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(player);
            make.right.equalTo(player);
            make.height.mas_equalTo(60);
            make.top.equalTo(player);
        }];
        
        [player.bgImgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(player);
            make.width.mas_equalTo(player);
            make.center.mas_equalTo(player);
        }];
        
        [player.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(player.topView).offset(5);
            make.height.mas_equalTo(30);
            make.top.mas_equalTo(player.topView).offset(5);
            make.width.mas_equalTo(30);
        }];
        
        [player.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(player.topView).offset(12);
            make.right.mas_equalTo(player.topView).offset(-12);
            make.top.mas_equalTo(player.topView).offset(12);
        }];
        
        [player.loadFailedLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(player);
            make.width.mas_equalTo(player);
            make.height.mas_equalTo(@30);
        }];
        
        [player.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self);
            make.right.mas_equalTo(self);
            make.height.mas_equalTo(40);
            make.bottom.mas_equalTo(self);
        }];
        
        [player.volumeView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(player.top).offset(ZCXHeightScale * 21);
            make.left.mas_equalTo(player.left).offset(ZCXWidthScale * 45);
            make.bottom.mas_equalTo(player.bottom).offset(-ZCXHeightScale * 24);
            make.width.mas_equalTo(ZCXWidthScale * 36);
        }];
        
        [player.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(player.top).offset(ZCXHeightScale * 21);
            make.right.mas_equalTo(player.right).offset(- ZCXWidthScale * 45);
            make.bottom.mas_equalTo(player.bottom).offset(- ZCXHeightScale * 24);
            make.width.mas_equalTo(ZCXWidthScale * 36);
        }];
        
        [self setNeedsUpdateConstraints];
        [self updateConstraintsIfNeeded];
        WS(weakSelf);
        
        [weakSelf.volumeView fullOrSmall:NO];
        [weakSelf.brightnessView fullOrSmall:NO];
        [weakSelf.brightnessView setImage:NO];
        
        
        /* player.isFullscreen = NO;
         player.btnFullScreen.selected = NO;
         //换上小图
         [self.btnPlayOrPause setImage:[UIImage imageNamed:@"pause_icon"] ?: [UIImage imageNamed:@"pause_icon"] forState:UIControlStateNormal];
         [self.btnPlayOrPause setImage:[UIImage imageNamed:@"play_icon"] ?: [UIImage imageNamed:@"play_white_icon"] forState:UIControlStateSelected];*/
        [player showSmallScreenWithPlayer:player];
    }completion:^(BOOL finished) {
        
    }];
}

//替换小图标
-(void) showSmallScreenWithPlayer :(DisplayerView *)player{
    [player.topView setHidden: YES];
    player.isFullscreen = NO;
    player.btnFullScreen.selected = NO;
    
    //是否可以滑动
    player.isFromHomePage = NO;
    player.closeBtn.selected = player.isFullscreen;
    [player.closeBtn setHidden:!player.isFullscreen];
    
    //换上小图
    [player.btnPlayOrPause setImage:[UIImage imageNamed:@"pause_icon"] ?: [UIImage imageNamed:@"pause_icon"] forState:UIControlStateNormal];
    [player.btnPlayOrPause setImage:[UIImage imageNamed:@"play_icon"] ?: [UIImage imageNamed:@"play_white_icon"] forState:UIControlStateSelected];
    
    [player showSmallScreenWithNetWork:player];
 
}


/**
 * 重置4G网络提示, 小屏幕转换
 *
 * @param player 当前播放器
 */
-(void) showSmallScreenWithNetWork:(DisplayerView *)player{
    [player.netWorkView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(player);
        make.height.mas_equalTo(player);
        make.center.mas_equalTo(player);
    }];
    
    [player.labNetWorkMention mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(player.netWorkView);
        make.height.equalTo(@30);
    }];
    
    //取消播放按钮
    [player.btnLeft mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(@30);
        make.width.mas_equalTo(@60);
        make.top.mas_equalTo(player.labNetWorkMention.bottom).offset(10);
        make.left.mas_equalTo(player.labNetWorkMention).offset(-12);
    }];
    
    //继续播放按钮
    [player.btnRight mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(@30);
        make.width.mas_equalTo(@60);
        make.top.mas_equalTo(player.labNetWorkMention.bottom).offset(10);
        make.right.mas_equalTo(player.labNetWorkMention).offset(14);
    }];
}
/**
 Description
 获取当前帧图片
 @return return value description
 */
-(UIImage*)getScreenShotImg{
    
    CMTime time = [self.videoOutPut itemTimeForHostTime:CACurrentMediaTime()];
    if (0 == time.value) {
        return nil;
    }
    
    //截取到对应的图片
    if ([self.videoOutPut hasNewPixelBufferForItemTime:time]) {
        CVPixelBufferRef lastSnapshotPixelBuffer = [self.videoOutPut copyPixelBufferForItemTime:time itemTimeForDisplay:NULL];
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:lastSnapshotPixelBuffer];
        CIContext *context = [CIContext contextWithOptions:NULL];
        CGRect rect = CGRectMake(0,
                                 0,
                                 CVPixelBufferGetWidth(lastSnapshotPixelBuffer),
                                 CVPixelBufferGetHeight(lastSnapshotPixelBuffer));
        CGImageRef cgImage = [context createCGImage:ciImage fromRect:rect];
        self.screenShotImg = [UIImage imageWithCGImage:cgImage];
        //当前帧的画面
        CGImageRelease(cgImage);
        
        return self.screenShotImg;
    }
    return nil;
}


@end
