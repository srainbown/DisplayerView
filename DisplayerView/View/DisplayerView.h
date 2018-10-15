//
//  DisplayerView.h
//  DisplayerView
//
//  Created by 紫川秀 on 2018/5/17.
//  Copyright © 2018年 dangbei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayerVolumeView.h"
@import MediaPlayer;
@import AVFoundation;
@class DisplayerView;

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};

// 播放器的几种状态
typedef NS_ENUM(NSInteger, DBCHDisplayerState) {
    DBCHDisplayerStateFailed,        // 播放失败
    DBCHDisplayerStateBuffering,     // 缓冲中
    DBCHDisplayerStatusReadyToPlay,  // 将要播放
    DBCHDisplayerStatePlaying,       // 播放中
    DBCHDisplayerStateStopped,       //暂停播放
    DBCHDisplayerStateFinished       //播放完毕
};
// 枚举值，包含播放器左上角的关闭按钮的类型
typedef NS_ENUM(NSInteger, CloseBtnStyle){
    CloseBtnStylePop, //pop箭头<-
    CloseBtnStyleClose  //关闭（X）
};
@protocol KYVedioPlayerDelegate <NSObject>
@optional
///播放器事件
//点击播放暂停按钮代理方法
-(void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer clickedPlayOrPauseButton:(UIButton *)playOrPauseBtn;
//点击关闭按钮代理方法
-(void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer clickedCloseButton:(UIButton *)closeBtn;
//点击全屏按钮代理方法
-(void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer clickedFullScreenButton:(UIButton *)fullScreenBtn;
//单击WMPlayer的代理方法
-(void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer singleTaped:(UITapGestureRecognizer *)singleTap;
//双击WMPlayer的代理方法
-(void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer doubleTaped:(UITapGestureRecognizer *)doubleTap;

//分享按钮
- (void)kyvedioPlayer:(DisplayerView *)kyvedioPlayer clickedShareButton:(UIButton *)btnShare;

///播放状态
//播放失败的代理方法
-(void)kyvedioPlayerFailedPlay:(DisplayerView *)kyvedioPlayer playerStatus:(DBCHDisplayerState)state;
//准备播放的代理方法
-(void)kyvedioPlayerReadyToPlay:(DisplayerView *)kyvedioPlayer playerStatus:(DBCHDisplayerState)state;
//播放完毕的代理方法
-(void)kyplayerFinishedPlay:(DisplayerView *)kyvedioPlayer;

//取消4g网络播放代理
-(void)kyPlayerCancelPlayer:(DisplayerView*)kyvedioPlayer;

@end


//播放器View
@interface DisplayerView : UIView

/**
 *  播放器player
 */
@property (nonatomic,retain ) AVPlayer*       player;
/**
 *playerLayer,可以修改frame
 */
@property (nonatomic,retain ) AVPlayerLayer*  playerLayer;

/** 播放器的代理 */
@property (nonatomic, weak)id <KYVedioPlayerDelegate> delegate;

/**设置播放器的大小和位置*/
@property (nonatomic, assign)CGRect      disPlayerFram;
/**
 *  底部操作工具栏
 */
@property (nonatomic,retain ) UIView*         bottomView;
/**
 *  顶部操作工具栏
 */
@property (nonatomic,retain ) UIView*         topView;

/**
 *  中间网络切换工具
 */
@property (nonatomic,retain ) UIView*         netWorkView;


/**
 *  显示播放视频的title
 */
@property (nonatomic,strong) UILabel*        titleLabel;
/**
 ＊  播放器状态
 */
@property (nonatomic, assign) DBCHDisplayerState   state;

@property (nonatomic, assign) DBCHDisplayerState   detailState;
/**
 ＊  播放器左上角按钮的类型
 */
@property (nonatomic, assign) CloseBtnStyle   closeBtnStyle;
/**
 *  定时器
 */
@property (nonatomic, retain) NSTimer*        autoDismissTimer;
/**
 *  BOOL值判断是否自动隐藏底部视图,默认是自动隐藏
 */
@property (nonatomic,assign ) BOOL            isAutoDismissBottomView;
/**
 *  BOOL值判断当前的状态
 */
@property (nonatomic,assign ) BOOL            isFullscreen;
/**
 *  控制全屏的按钮
 */
@property (nonatomic,retain ) UIButton*       btnFullScreen;
/**
 *  播放暂停按钮
 */
@property (nonatomic,retain ) UIButton*       btnPlayOrPause;

@property (nonatomic, strong ) UIImageView           *fastImageView;

@property (nonatomic, strong) UIView                 *fastView;

@property (nonatomic, strong) UILabel                *fastTimeLabel;
@property (nonatomic, strong) UILabel                *allTimeLabel;

@property (nonatomic, strong) UIProgressView         *fastProgressView;

@property (nonatomic, strong) UIImageView               *bgImgView;                     //cell中的背景图片

@property (nonatomic, assign) BOOL                      isForbiddenFullScreen;           //是否允许全屏

@property (nonatomic, assign) BOOL                      isFromHomePage;

@property (nonatomic, assign) BOOL                      isFromDetailView;

/**
 *  左上角关闭按钮
 */
//@property (nonatomic,retain ) UIButton*       btnClose;
/**
 *  左上角关闭按钮
 */
@property (nonatomic,retain ) UIButton       *closeBtn;
/**
 *  显示加载失败的UILabel
 */
@property (nonatomic,strong) UILabel*        labLoadFailed;
/**
 *  当前播放的item
 */
@property (nonatomic, retain) AVPlayerItem*   currentItem;
/**
 *  菊花（加载框）
 */
@property (nonatomic,strong) UIActivityIndicatorView * loadingView;
/**
 *  BOOL值判断当前的播放状态
 */
@property (nonatomic,assign ) BOOL       isPlaying;
/**
 *  设置播放视频的USRLString，可以是本地的路径也可以是http的网络路径
 */
@property (nonatomic,copy) NSString*       URLString;
/**
 *  设置播放器的homePageModel
 */
@property (nonatomic, strong) VedioModel *vedioModel;

/**
 *  跳到time处播放
 *  seekTime 这个时刻，这个时间点
 */
@property (nonatomic, assign) double  seekTime;

//视频时长
@property (nonatomic, strong) NSString *  allTime;
/**
 *  进度条的颜色
 *  progressColor
 */
@property (nonatomic,strong)  UIColor *  progressColor;


@property (nonatomic, assign) BOOL isFromDownLoadedView;

//音量调节指示器
@property (nonatomic , strong) DisplayerVolumeView *volumeView;
//亮度调节指示器
@property (nonatomic , strong) DisplayerVolumeView *brightnessView;


/**
 *  播放
 */
- (void)play;

/**
 * 暂停
 */
- (void)pause;

//获取播放器单例
+(DisplayerView *)sharedInstance;
//获取当前帧图片
-(UIImage*)getScreenShotImg;
/**
 *  获取正在播放的时间点
 *
 *  @return double的一个时间点
 */
- (double)currentTime;

/**
 * 重置播放器
 */
- (void)resetDisPlayer;

/**
 * 关闭播放器
 */
-(void)closeDisPlayer;

/**
 *  全屏显示播放
 ＊ @param interfaceOrientation 方向
 ＊ @param player 当前播放器
 ＊ @param fatherView 当前父视图
 **/
-(void)showFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation player:(DisplayerView *)player withFatherView:(UIView *)fatherView;

/**
 *  小屏幕显示播放
 ＊ @param player 当前播放器
 ＊ @param fatherView 当前父视图
 ＊ @param playerFrame 小屏幕的Frame
 **/
-(void)showSmallScreenWithPlayer:(DisplayerView *)player withFatherView:(UIView *)fatherView withFrame:(CGRect )playerFrame;


/**
 * 替换小屏的内容
 */
-(void) showSmallScreenWithPlayer: (DisplayerView *)player;


/**
 * 重置4G网络提示
 *
 * @param player 当前播放器
 */
-(void) showSmallScreenWithNetWork:(DisplayerView *)player;


@end
