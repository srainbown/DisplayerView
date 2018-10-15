//
//  VedioModel.m
//  DisplayerView
//
//  Created by 紫川秀 on 2018/5/17.
//  Copyright © 2018年 dangbei. All rights reserved.
//
//"id": 视频ID "title": 视频标题 "video": 视频地址 "pic": 视频截图 "playNum": 播放量 "likeNum": 喜欢次数 "tags": 标签(多个标签逗号隔开) "updateTime": 更新时间

#import "VedioModel.h"

@implementation VedioModel

-(instancetype)initWithDic:(NSDictionary *)dic{
    self = [super init];
    if (self) {
        //解析过程
        self.vedioID = dic[@"id"];
        self.vedioTitle = dic[@"title"];
        self.imageURL = dic[@"pic"];
//        self.videoURL = __AuthenticationVideoURl(dic[@"video"]);
//        self.videoOriginal = __AuthenticationVideoURl(dic[@"videoOriginal"]);
//        self.videoCacheURL = __AuthenticationVideoURl(dic[@"videoDwnurl"]);
//        self.videoCacheOrigURL = __AuthenticationVideoURl(dic[@"videoOrigDwnurl"]);
        self.videoMd5 = dic[@"videoMd5"];
        self.videoSize = dic[@"videoSize"];
        self.playLenth = dic[@"duration"];
        self.playNum = dic[@"playNum"];
        self.numLove = dic[@"likeNum"];
        self.updateTime = dic[@"updateTime"];
        self.catid = dic[@"cateId"];
    }
    
    return self;
}

@end
