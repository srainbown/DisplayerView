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

@property (nonatomic, strong) NSString * upNum;         //顶次数
@property (nonatomic, strong) NSString * dwnNum;        //踩次数
@property (nonatomic, strong) NSString * isLike;        //是否喜欢(1是 2取消)
@property (nonatomic, strong) NSString * isUpdwn;       //是否顶踩(1顶 2踩)
@property (nonatomic, strong) NSString * commentNum;    //评论数量
@property (nonatomic, strong) NSString * step;          //-1 审核不通过 1:审核中 2:审核通过 8:已发布

@property (nonatomic, strong) NSString * source;        //发布者
@property (nonatomic, strong) NSString * filmID;        //相关电影ID
@property (nonatomic, strong) NSString * filmTitle;     //相关电影的名字

//系列ID
@property (nonatomic, copy) NSString *seriesID;
//系列标题
@property (nonatomic, copy) NSString *seriesTitle;
// 系列视频数量
@property (nonatomic, copy) NSString *seriesVideoNum;
//是否关注
@property (nonatomic, copy) NSString *isSubscribe;

//新增视频
@property (nonatomic, copy) NSString *videoUpd;



///**
// *自定义cell的高度
// */
//@property (nonatomic,assign) CGFloat curCellHeight;
//
//@property (nonatomic, strong) NSIndexPath *indexPath;

-(void)setSeries:(NSDictionary *)dict;

//初始化
-(instancetype)initWithDic:(NSDictionary *)dic;

-(void) setTags: (NSArray*) arryTag tags: (NSString*) tags;

-(void)setValue:(id)value forUndefinedKey:(NSString *)key;

@end
