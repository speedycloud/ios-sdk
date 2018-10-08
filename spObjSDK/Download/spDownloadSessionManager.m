//
//  spDownloadSessionManager.m
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import "spDownloadSessionManager.h"
#import "spHeaderSignOrToken.h"
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
#import "NSURLSession+spCorrectedResumeData.h"

/**
 *  下载模型
 */
@interface spDownloadModel ()

// >>>>>>>>>>>>>>>>>>>>>>>>>>  task info
// 下载状态
@property (nonatomic, assign) spDownloadState state;
// 下载任务
@property (nonatomic, strong) NSURLSessionDownloadTask *task;
// 文件流
@property (nonatomic, strong) NSOutputStream *stream;
// 下载文件路径,下载完成后有值,把它移动到你的目录
@property (nonatomic, strong) NSString *filePath;
// 下载时间
@property (nonatomic, strong) NSDate *downloadDate;
// 断点续传需要设置这个数据
@property (nonatomic, strong) NSData *resumeData;
// 手动取消当做暂停
@property (nonatomic, assign) BOOL manualCancle;

@end

/**
 *  下载进度
 */
@interface spDownloadProgress ()
// 续传大小
@property (nonatomic, assign) int64_t resumeBytesWritten;
// 这次写入的数量
@property (nonatomic, assign) int64_t bytesWritten;
// 已下载的数量
@property (nonatomic, assign) int64_t totalBytesWritten;
// 文件的总大小
@property (nonatomic, assign) int64_t totalBytesExpectedToWrite;
// 下载进度
@property (nonatomic, assign) float progress;
// 下载速度
@property (nonatomic, assign) float speed;
// 下载剩余时间
@property (nonatomic, assign) int remainingTime;

@end

@interface spDownloadSessionManager ()

// >>>>>>>>>>>>>>>>>>>>>>>>>>  file info
// 文件管理
@property (nonatomic, strong) NSFileManager *fileManager;
// 缓存文件目录
@property (nonatomic, strong) NSString *downloadDirectory;

// >>>>>>>>>>>>>>>>>>>>>>>>>>  session info
// 下载seesion会话
@property (nonatomic, strong) NSURLSession *session;
// 下载模型字典 key = url, value = model
@property (nonatomic, strong) NSMutableDictionary *downloadingModelDic;
// 下载中的模型
@property (nonatomic, strong) NSMutableArray *waitingDownloadModels;
// 等待中的模型
@property (nonatomic, strong) NSMutableArray *downloadingModels;
// 回调代理的队列
@property (strong, nonatomic) NSOperationQueue *queue;

@property (nonatomic, strong) spHeaderSignOrToken *headerSignToken;

@end

#define IS_IOS8ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8)
#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)

@implementation spDownloadSessionManager

+ (spDownloadSessionManager *)manager:(NSString*)accesskey
                            secretKey:(NSString*)secretkey
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init:accesskey secretKey:secretkey];
    });
    return sharedInstance;
}

- (instancetype)init:(NSString*)accesskey
           secretKey:(NSString*)secretkey
{
    if (self = [super init]) {
        _backgroundConfigure = @"spDownloadSessionManager.backgroundConfigure";
        _maxDownloadCount = 1;
        _resumeDownloadFIFO = YES;
        _isBatchDownload = NO;
        _headerSignToken = [[spHeaderSignOrToken alloc] initWithData:accesskey withSecretKey:secretkey];
    }
    return self;
}

- (void)configureBackroundSession
{
    if (!_backgroundConfigure) {
        return;
    }
    [self session];
}

#pragma mark - getter

- (NSFileManager *)fileManager
{
    if (!_fileManager) {
        _fileManager = [[NSFileManager alloc]init];
    }
    return _fileManager;
}

- (NSURLSession *)session
{
    if (!_session) {
        if (_backgroundConfigure) {
            if (IS_IOS8ORLATER) {
                NSURLSessionConfiguration *configure = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_backgroundConfigure];
                _session = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:self.queue];
            }else{
                _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfiguration:_backgroundConfigure]delegate:self delegateQueue:self.queue];
            }
        }else {
            _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.queue];
        }
    }
    return _session;
}

- (NSOperationQueue *)queue
{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc]init];
        _queue.maxConcurrentOperationCount = 1;
    }
    return _queue;
}

- (NSString *)downloadDirectory
{
    if (!_downloadDirectory) {
        _downloadDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"XDYDownloadCache"];
        [self createDirectory:_downloadDirectory];
    }
    return _downloadDirectory;
}

- (NSMutableDictionary *)downloadingModelDic
{
    if (!_downloadingModelDic) {
        _downloadingModelDic = [NSMutableDictionary dictionary];
    }
    return _downloadingModelDic;
}

- (NSMutableArray *)waitingDownloadModels
{
    if (!_waitingDownloadModels) {
        _waitingDownloadModels = [NSMutableArray array];
    }
    return _waitingDownloadModels;
}

- (NSMutableArray *)downloadingModels
{
    if (!_downloadingModels) {
        _downloadingModels = [NSMutableArray array];
    }
    return _downloadingModels;
}

#pragma mark - downlaod

// 开始下载
- (spDownloadModel *)startDownloadURLString:(NSString *)URLString toDestinationPath:(NSString *)destinationPath progress:(spDownloadProgressBlock)progress state:(spDownloadStateBlock)state
{
    // 验证下载地址
    if (!URLString) {
        NSLog(@"dwonloadURL can't nil");
        return nil;
    }
    
    spDownloadModel *downloadModel = [self downLoadingModelForURLString:URLString];
    
    if (!downloadModel || ![downloadModel.filePath isEqualToString:destinationPath]) {
        downloadModel = [[spDownloadModel alloc]initWithURLString:URLString filePath:destinationPath];
    }
    
    [self startWithDownloadModel:downloadModel bucket:nil obj:nil progress:progress state:state];
    
    return downloadModel;
}

- (void)startWithDownloadModel:(spDownloadModel *)downloadModel
                        bucket:(NSString *)bucket
                           obj:(NSString*)obj
                      progress:(spDownloadProgressBlock)progress
                         state:(spDownloadStateBlock)state
{
    downloadModel.progressBlock = progress;
    downloadModel.stateBlock = state;
    
    [self startWithDownloadModel:downloadModel bucket:bucket obj:obj];
}


- (void)startWithDownloadModel:(spDownloadModel *)downloadModel
                        bucket:(NSString *)bucket
                           obj:(NSString*)obj
{
    if (!downloadModel) {
        return;
    }
    
    if (downloadModel.state == spDownloadStateReadying) {
        [self downloadModel:downloadModel didChangeState:spDownloadStateReadying filePath:nil error:nil];
        return;
    }

    // 验证是否存在
    if (downloadModel.task && downloadModel.task.state == NSURLSessionTaskStateRunning) {
        downloadModel.state = spDownloadStateRunning;
        [self downloadModel:downloadModel didChangeState:spDownloadStateRunning filePath:nil error:nil];
        return;
    }
    
    // 后台下载设置
    [self configirebackgroundSessionTasksWithDownloadModel:downloadModel];
    
    [self resumeWithDownloadModel:downloadModel bucket:bucket obj:obj];
}

// 恢复下载
- (void)resumeWithDownloadModel:(spDownloadModel *)downloadModel
                         bucket:(NSString *)bucket
                            obj:(NSString*)obj
{
    if (!downloadModel) {
        return;
    }
    
    if (![self canResumeDownlaodModel:downloadModel]) {
        return;
    }
    
    // 如果task 不存在 或者 取消了
    if (!downloadModel.task || downloadModel.task.state == NSURLSessionTaskStateCanceling) {
        
        NSData *resumeData = [self resumeDataFromFileWithDownloadModel:downloadModel];
        
        if ([self isValideResumeData:resumeData]) {
            if (IS_IOS10ORLATER) {
                downloadModel.task = [self.session downloadTaskWithCorrectResumeData:resumeData];
            }else {
                 downloadModel.task = [self.session downloadTaskWithResumeData:resumeData];
            }
        }else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:downloadModel.downloadURL]];
            NSString * path = [NSString stringWithFormat:@"%@/%@",bucket,obj];
            NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"application/x-www-form-urlencoded", @"content_type", path, @"url",@"GET", @"http_method",nil];
            NSDictionary* headers = [_headerSignToken generateHeaders:@"GET" params:params isJson:false];
            [request setAllHTTPHeaderFields:headers];
            [request setHTTPMethod:@"GET"];
            downloadModel.task = [self.session downloadTaskWithRequest:request];
        }
        downloadModel.task.taskDescription = downloadModel.downloadURL;
        downloadModel.downloadDate = [NSDate date];
    }

    if (!downloadModel.downloadDate) {
        downloadModel.downloadDate = [NSDate date];
    }
    
    if (![self.downloadingModelDic objectForKey:downloadModel.downloadURL]) {
        self.downloadingModelDic[downloadModel.downloadURL] = downloadModel;
    }
    
    [downloadModel.task resume];
    
    downloadModel.state = spDownloadStateRunning;
    [self downloadModel:downloadModel didChangeState:spDownloadStateRunning filePath:nil error:nil];
}

- (BOOL)isValideResumeData:(NSData *)resumeData
{
    if (!resumeData || resumeData.length == 0) {
        return NO;
    }
    return YES;
}

// 暂停下载
- (void)suspendWithDownloadModel:(spDownloadModel *)downloadModel
{
    if (!downloadModel.manualCancle) {
        downloadModel.manualCancle = YES;
        [self cancleWithDownloadModel:downloadModel clearResumeData:NO];
    }
}

// 取消下载
- (void)cancleWithDownloadModel:(spDownloadModel *)downloadModel
{
    if (downloadModel.state != spDownloadStateCompleted && downloadModel.state != spDownloadStateFailed){
        [self cancleWithDownloadModel:downloadModel clearResumeData:NO];
    }
}

// 删除下载
- (void)deleteFileWithDownloadModel:(spDownloadModel *)downloadModel
{
    if (!downloadModel || !downloadModel.filePath) {
        return;
    }
    
    [self cancleWithDownloadModel:downloadModel clearResumeData:YES];
    [self deleteFileIfExist:downloadModel.filePath];
}

- (void)deleteAllFileWithDownloadDirectory:(NSString *)downloadDirectory
{
    if (!downloadDirectory) {
        downloadDirectory = self.downloadDirectory;
    }
    
     for (spDownloadModel *downloadModel in [self.downloadingModelDic allValues]) {
          if ([downloadModel.downloadDirectory isEqualToString:downloadDirectory]) {
              [self cancleWithDownloadModel:downloadModel clearResumeData:YES];
          }
     }
    // 删除沙盒中所有资源
    [self.fileManager removeItemAtPath:downloadDirectory error:nil];
}

// 取消下载 是否删除resumeData
- (void)cancleWithDownloadModel:(spDownloadModel *)downloadModel clearResumeData:(BOOL)clearResumeData
{
    if (!downloadModel.task && downloadModel.state == spDownloadStateReadying) {
        [self removeDownLoadingModelForURLString:downloadModel.downloadURL];
        @synchronized (self) {
            [self.waitingDownloadModels removeObject:downloadModel];
        }
        downloadModel.state = spDownloadStateNone;
        [self downloadModel:downloadModel didChangeState:spDownloadStateNone filePath:nil error:nil];
        return;
    }
    if (clearResumeData) {
        downloadModel.state = spDownloadStateNone;
        downloadModel.resumeData = nil;
        [self deleteFileIfExist:[self resumeDataPathWithDownloadURL:downloadModel.downloadURL]];
        [downloadModel.task cancel];
    }else {
        [(NSURLSessionDownloadTask *)downloadModel.task cancelByProducingResumeData:^(NSData *resumeData){
        }];
    }
}

- (void)willResumeNextWithDowloadModel:(spDownloadModel *)downloadModel
{
    if (_isBatchDownload) {
        return;
    }
    
    @synchronized (self) {
        [self.downloadingModels removeObject:downloadModel];
        // 还有未下载的
        if (self.waitingDownloadModels.count > 0) {
            [self resumeWithDownloadModel:_resumeDownloadFIFO ? self.waitingDownloadModels.firstObject:self.waitingDownloadModels.lastObject bucket:nil obj:nil];
        }
    }
}

- (BOOL)canResumeDownlaodModel:(spDownloadModel *)downloadModel
{
    if (_isBatchDownload) {
        return YES;
    }
    
    @synchronized (self) {
        if (self.downloadingModels.count >= _maxDownloadCount ) {
            if ([self.waitingDownloadModels indexOfObject:downloadModel] == NSNotFound) {
                [self.waitingDownloadModels addObject:downloadModel];
                self.downloadingModelDic[downloadModel.downloadURL] = downloadModel;
            }
            downloadModel.state = spDownloadStateReadying;
            [self downloadModel:downloadModel didChangeState:spDownloadStateReadying filePath:nil error:nil];
            return NO;
        }
        
        if ([self.waitingDownloadModels indexOfObject:downloadModel] != NSNotFound) {
            [self.waitingDownloadModels removeObject:downloadModel];
        }
        
        if ([self.downloadingModels indexOfObject:downloadModel] == NSNotFound) {
            [self.downloadingModels addObject:downloadModel];
        }
        return YES;
    }
}

#pragma mark - configire background task

// 配置后台后台下载session
- (void)configirebackgroundSessionTasksWithDownloadModel:(spDownloadModel *)downloadModel
{
    if (!_backgroundConfigure) {
        return ;
    }
    
    NSURLSessionDownloadTask *task = [self backgroundSessionTasksWithDownloadModel:downloadModel];
    if (!task) {
        return;
    }
    
    downloadModel.task = task;
    if (task.state == NSURLSessionTaskStateRunning) {
        [task suspend];
    }
}

- (NSURLSessionDownloadTask *)backgroundSessionTasksWithDownloadModel:(spDownloadModel *)downloadModel
{
    NSArray *tasks = [self sessionDownloadTasks];
    for (NSURLSessionDownloadTask *task in tasks) {
        if (task.state == NSURLSessionTaskStateRunning || task.state == NSURLSessionTaskStateSuspended) {
            if ([downloadModel.downloadURL isEqualToString:task.taskDescription]) {
                return task;
            }
        }
    }
    return nil;
}

// 获取所以的后台下载session
- (NSArray *)sessionDownloadTasks
{
    __block NSArray *tasks = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        tasks = downloadTasks;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return tasks;
}

#pragma mark - public

// 获取下载模型
- (spDownloadModel *)downLoadingModelForURLString:(NSString *)URLString
{
    return [self.downloadingModelDic objectForKey:URLString];
}

// 是否已经下载
- (BOOL)isDownloadCompletedWithDownloadModel:(spDownloadModel *)downloadModel
{
    return [self.fileManager fileExistsAtPath:downloadModel.filePath];
}

// 取消所有后台
- (void)cancleAllBackgroundSessionTasks
{
    if (!_backgroundConfigure) {
        return;
    }
    
    for (NSURLSessionDownloadTask *task in [self sessionDownloadTasks]) {
        [task cancelByProducingResumeData:^(NSData * resumeData) {
            }];
    }
}

#pragma mark - private

- (void)downloadModel:(spDownloadModel *)downloadModel didChangeState:(spDownloadState)state filePath:(NSString *)filePath error:(NSError *)error
{
    if (_delegate && [_delegate respondsToSelector:@selector(downloadModel:didChangeState:filePath:error:)]) {
        [_delegate downloadModel:downloadModel didChangeState:state filePath:filePath error:error];
    }
    
    if (downloadModel.stateBlock) {
        downloadModel.stateBlock(state,filePath,error);
    }
}

- (void)downloadModel:(spDownloadModel *)downloadModel updateProgress:(spDownloadProgress *)progress
{
    if (_delegate && [_delegate respondsToSelector:@selector(downloadModel:didUpdateProgress:)]) {
        [_delegate downloadModel:downloadModel didUpdateProgress:progress];
    }
    
    if (downloadModel.progressBlock) {
        downloadModel.progressBlock(progress);
    }
}

- (void)removeDownLoadingModelForURLString:(NSString *)URLString
{
    [self.downloadingModelDic removeObjectForKey:URLString];
}

// 获取resumeData
- (NSData *)resumeDataFromFileWithDownloadModel:(spDownloadModel *)downloadModel
{
    if (downloadModel.resumeData) {
        return downloadModel.resumeData;
    }
    NSString *resumeDataPath = [self resumeDataPathWithDownloadURL:downloadModel.downloadURL];
    
    if ([_fileManager fileExistsAtPath:resumeDataPath]) {
        NSData *resumeData = [NSData dataWithContentsOfFile:resumeDataPath];
        return resumeData;
    }
    return nil;
}

// resumeData 路径
- (NSString *)resumeDataPathWithDownloadURL:(NSString *)downloadURL
{
    NSString *resumeFileName = [[self class] md5:downloadURL];
    return [self.downloadDirectory stringByAppendingPathComponent:resumeFileName];
}

+ (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    if (cStr == NULL) {
        cStr = "";
    }
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

//  创建缓存目录文件
- (void)createDirectory:(NSString *)directory
{
    if (![self.fileManager fileExistsAtPath:directory]) {
        [self.fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

- (void)moveFileAtURL:(NSURL *)srcURL toPath:(NSString *)dstPath
{
    if (!dstPath) {
        NSLog(@"error filePath is nil!");
        return;
    }
    NSError *error = nil;
    if ([self.fileManager fileExistsAtPath:dstPath] ) {
        [self.fileManager removeItemAtPath:dstPath error:&error];
        if (error) {
            NSLog(@"removeItem error %@",error);
        }
    }
    
    NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
    [self.fileManager moveItemAtURL:srcURL toURL:dstURL error:&error];
    if (error){
        NSLog(@"moveItem error:%@",error);
    }
}

- (void)deleteFileIfExist:(NSString *)filePath
{
    if ([self.fileManager fileExistsAtPath:filePath] ) {
        NSError *error  = nil;
        [self.fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"emoveItem error %@",error);
        }
    }
}


#pragma mark - NSURLSessionDownloadDelegate

// 恢复下载
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    spDownloadModel *downloadModel = [self downLoadingModelForURLString:downloadTask.taskDescription];
    
    if (!downloadModel || downloadModel.state == spDownloadStateSuspended) {
        return;
    }
    
    downloadModel.progress.resumeBytesWritten = fileOffset;
}

// 监听文件下载进度
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    spDownloadModel *downloadModel = [self downLoadingModelForURLString:downloadTask.taskDescription];
    
    if (!downloadModel || downloadModel.state == spDownloadStateSuspended) {
        return;
    }
    
    float progress = (double)totalBytesWritten/totalBytesExpectedToWrite;
    
    int64_t resumeBytesWritten = downloadModel.progress.resumeBytesWritten;
    
    NSTimeInterval downloadTime = -1 * [downloadModel.downloadDate timeIntervalSinceNow];
    float speed = (totalBytesWritten - resumeBytesWritten) / downloadTime;
    
    int64_t remainingContentLength = totalBytesExpectedToWrite - totalBytesWritten;
    int remainingTime = ceilf(remainingContentLength / speed);
    
    downloadModel.progress.bytesWritten = bytesWritten;
    downloadModel.progress.totalBytesWritten = totalBytesWritten;
    downloadModel.progress.totalBytesExpectedToWrite = totalBytesExpectedToWrite;
    downloadModel.progress.progress = progress;
    downloadModel.progress.speed = speed;
    downloadModel.progress.remainingTime = remainingTime;
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self downloadModel:downloadModel updateProgress:downloadModel.progress];
    });
}


// 下载成功
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    spDownloadModel *downloadModel = [self downLoadingModelForURLString:downloadTask.taskDescription];
    if (!downloadModel && _backgroundSessionDownloadCompleteBlock) {
        NSString *filePath = _backgroundSessionDownloadCompleteBlock(downloadTask.taskDescription);
        // 移动文件到下载目录
        [self createDirectory:filePath.stringByDeletingLastPathComponent];
        [self moveFileAtURL:location toPath:filePath];
        return;
    }
    
    if (location) {
        // 移动文件到下载目录
        [self createDirectory:downloadModel.downloadDirectory];
        [self moveFileAtURL:location toPath:downloadModel.filePath];
    }
}

// 下载完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    spDownloadModel *downloadModel = [self downLoadingModelForURLString:task.taskDescription];
    
    if (!downloadModel) {
        NSData *resumeData = error ? [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]:nil;
        if (resumeData) {
            [self createDirectory:_downloadDirectory];
            [resumeData writeToFile:[self resumeDataPathWithDownloadURL:task.taskDescription] atomically:YES];
        }else {
            [self deleteFileIfExist:[self resumeDataPathWithDownloadURL:task.taskDescription]];
        }
        return;
    }

    NSData *resumeData = nil;
    if (error) {
        resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
    }
    // 缓存resumeData
    if (resumeData) {
        downloadModel.resumeData = resumeData;
        [self createDirectory:_downloadDirectory];
        [downloadModel.resumeData writeToFile:[self resumeDataPathWithDownloadURL:downloadModel.downloadURL] atomically:YES];
    }else {
        downloadModel.resumeData = nil;
        [self deleteFileIfExist:[self resumeDataPathWithDownloadURL:downloadModel.downloadURL]];
    }
    
    downloadModel.progress.resumeBytesWritten = 0;
    downloadModel.task = nil;
    [self removeDownLoadingModelForURLString:downloadModel.downloadURL];
    
    if (downloadModel.manualCancle) {
        // 手动取消，当做暂停
        dispatch_async(dispatch_get_main_queue(), ^(){
            downloadModel.manualCancle = NO;
            downloadModel.state = spDownloadStateSuspended;
            [self downloadModel:downloadModel didChangeState:spDownloadStateSuspended filePath:nil error:nil];
            [self willResumeNextWithDowloadModel:downloadModel];
        });
    }else if (error){
        
        if (downloadModel.state == spDownloadStateNone) {
            // 删除下载
            dispatch_async(dispatch_get_main_queue(), ^(){
                downloadModel.state = spDownloadStateNone;
                [self downloadModel:downloadModel didChangeState:spDownloadStateNone filePath:nil error:error];
                [self willResumeNextWithDowloadModel:downloadModel];
            });
        }else {
            // 下载失败
            dispatch_async(dispatch_get_main_queue(), ^(){
                downloadModel.state = spDownloadStateFailed;
                [self downloadModel:downloadModel didChangeState:spDownloadStateFailed filePath:nil error:error];
                [self willResumeNextWithDowloadModel:downloadModel];
            });
        }
    }else {
        // 下载完成
        dispatch_async(dispatch_get_main_queue(), ^(){
            downloadModel.state = spDownloadStateCompleted;
            [self downloadModel:downloadModel didChangeState:spDownloadStateCompleted filePath:downloadModel.filePath error:nil];
            [self willResumeNextWithDowloadModel:downloadModel];
        });
    }

}

// 后台session下载完成
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    if (self.backgroundSessionCompletionHandler) {
        self.backgroundSessionCompletionHandler();
    }
}

@end
