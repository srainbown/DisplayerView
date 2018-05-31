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
//        NSString* strTag = dic[@"tags"];
//        self.vedioTags = __GetTagName(strTag);
        self.updateTime = dic[@"updateTime"];
        self.catid = dic[@"cateId"];
        //self.catid = @"99";
        self.source = dic[@"source"];
        self.upNum = dic[@"upNum"];
        self.dwnNum = dic[@"dwnNum"];
        self.isLike = dic[@"isLike"];
        self.isUpdwn = dic[@"isUpdwn"];
        self.commentNum = dic[@"commentsCount"];
        self.step = dic[@"step"];
        self.filmID = dic[@"filmId"];
        self.filmTitle = dic[@"filmTitle"];
        
    }
    
    return self;
    
}

-(void)setSeries:(NSDictionary *)dict{
    
    self.seriesID = dict[@"id"];
    self.seriesTitle = dict[@"title"];
    self.seriesVideoNum = dict[@"videoNum"];
    self.isSubscribe = dict[@"isSubscribe"];
    self.videoUpd = [NSString stringWithFormat:@"%@",dict[@"videoUpd"]];
    
}

//-(void) setTags: (NSArray*) arryTag tags: (NSString*) tags{
//    self.vedioTags = [DBCHTagsModel analysisTags: arryTag tagID:tags];
//}

////kvc方法，过滤videoURL，videoCacheURL,vedioTags等被特殊处理的属性
//-(void)setValue:(id)value forUndefinedKey:(NSString *)key{
//
//    if([key isEqualToString:@"videoURL"])
//    {
//        //视频地址鉴权
//        self.videoURL = __AuthenticationVideoURl(value);
//    }
//    if([key isEqualToString:@"videoCacheURL"])
//    {
//
//        //视频地址鉴权
//        self.videoCacheURL = __AuthenticationVideoURl(value);
//    }
//    if([key isEqualToString:@"vedioTags"])
//    {
//        //tag解析方法
//        self.vedioTags = __GetTagName(value);
//    }
//
//}

@end
