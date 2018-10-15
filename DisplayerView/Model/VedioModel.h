//
//  VedioModel.h
//  DisplayerView
//
//  Created by 紫川秀 on 2018/5/17.
//  Copyright © 2018年 dangbei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VedioModel : NSObject

@property (nonatomic, strong) NSString * vedioID;
@property (nonatomic, strong) NSString * vedioTitle;
@property (nonatomic, strong) NSString * imageURL;
@property (nonatomic, strong) NSString * videoURL;      //高清地址
@property (nonatomic, strong) NSString * videoOriginal; //原视频地址
@property (nonatomic, strong) NSString * videoCacheURL; //视频下载地址
@property (nonatomic, strong) NSString * videoCacheOrigURL; //视频下载原话地址
@property (nonatomic, strong) NSString * videoMd5;      //md5效验
@property (nonatomic, strong) NSString * videoSize;     //视频大小
@property (nonatomic, strong) NSString * playLenth;     //视频长度
@property (nonatomic, strong) NSString * playNum;       //播放数量
@property (nonatomic, strong) NSString * numLove;       //多少人喜爱
@property (nonatomic, strong) NSString * vedioTags;     //标签
@property (nonatomic, strong) NSString * updateTime;
@property (nonatomic, strong) NSString * catid;         //视频分类ID

//初始化
-(instancetype)initWithDic:(NSDictionary *)dic;

@end
