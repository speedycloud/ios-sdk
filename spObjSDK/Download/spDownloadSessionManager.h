//
//  spDownloadSessionManager.h
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "spDownloadModel.h"
#import "spDownloadDelegate.h"

/**
 *  下载管理类 封装NSURLSessionDownloadTask
 */
@interface spDownloadSessionManager : NSObject<NSURLSessionDownloadDelegate>

// 下载代理
@property (nonatomic,weak) id<spDownloadDelegate> delegate;

// 等待中的模型 只读
@property (nonatomic, strong,readonly) NSMutableArray *waitingDownloadModels;

// 下载中的模型 只读
@property (nonatomic, strong,readonly) NSMutableArray *downloadingModels;

// 最大下载数
@property (nonatomic, assign) NSInteger maxDownloadCount;

// 等待下载队列 先进先出 默认YES， 当NO时，先进后出
@property (nonatomic, assign) BOOL resumeDownloadFIFO;

// 全部并发 默认NO, 当YES时，忽略maxDownloadCount
@property (nonatomic, assign) BOOL isBatchDownload;

// 后台session configure
@property (nonatomic, strong) NSString *backgroundConfigure;
@property (nonatomic, copy) void (^backgroundSessionCompletionHandler)();

// 后台下载完成后调用 返回文件保存路径filePath
@property (nonatomic, copy) NSString *(^backgroundSessionDownloadCompleteBlock)(NSString *downloadURL);

// 单例
+ (spDownloadSessionManager *)manager:(NSString*)accesskey secretKey:(NSString*)secretkey;

// 配置后台session
- (void)configureBackroundSession;

// 获取正在下载模型
- (spDownloadModel *)downLoadingModelForURLString:(NSString *)URLString;

// 获取后台运行task
- (NSURLSessionDownloadTask *)backgroundSessionTasksWithDownloadModel:(spDownloadModel *)downloadModel;

// 是否已经下载
- (BOOL)isDownloadCompletedWithDownloadModel:(spDownloadModel *)downloadModel;

// 取消所有完成或失败后台task
- (void)cancleAllBackgroundSessionTasks;

// 开始下载
- (spDownloadModel *)startDownloadURLString:(NSString *)URLString toDestinationPath:(NSString *)destinationPath progress:(spDownloadProgressBlock)progress state:(spDownloadStateBlock)state;

// 开始下载
- (void)startWithDownloadModel:(spDownloadModel *)downloadModel bucket:(NSString *)bucket
                           obj:(NSString*)obj;

// 开始下载
- (void)startWithDownloadModel:(spDownloadModel *)downloadModel bucket:(NSString *)bucket
                           obj:(NSString*)obj progress:(spDownloadProgressBlock)progress state:(spDownloadStateBlock)state;

// 恢复下载（除非确定对这个model进行了suspend，否则使用start）
- (void)resumeWithDownloadModel:(spDownloadModel *)downloadModel bucket:(NSString *)bucket
                            obj:(NSString*)obj;

// 暂停下载
- (void)suspendWithDownloadModel:(spDownloadModel *)downloadModel;

// 取消下载
- (void)cancleWithDownloadModel:(spDownloadModel *)downloadModel;

// 删除下载
- (void)deleteFileWithDownloadModel:(spDownloadModel *)downloadModel;

// 删除下载
- (void)deleteAllFileWithDownloadDirectory:(NSString *)downloadDirectory;

@end
