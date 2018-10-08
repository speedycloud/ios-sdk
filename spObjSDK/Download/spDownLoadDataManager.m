//
//  spDownLoadDataManager.m
//  spDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import "spDownLoadDataManager.h"
#import "spHeaderSignOrToken.h"

/**
 *  下载模型
 */
@interface spDownloadModel ()

// >>>>>>>>>>>>>>>>>>>>>>>>>>  task info
// 下载状态
@property (nonatomic, assign) spDownloadState state;
// 下载任务
@property (nonatomic, strong) NSURLSessionDataTask *task;
// 文件流
@property (nonatomic, strong) NSOutputStream *stream;
// 下载文件路径
@property (nonatomic, strong) NSString *filePath;
// 下载时间
@property (nonatomic, strong) NSDate *downloadDate;
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


@interface spDownLoadDataManager ()

// >>>>>>>>>>>>>>>>>>>>>>>>>>  file info
// 文件管理
@property (nonatomic, strong) NSFileManager *fileManager;
// 缓存文件目录
@property (nonatomic, strong) NSString *downloadDirectory;

// >>>>>>>>>>>>>>>>>>>>>>>>>>  session info
// 下载seesion会话
@property (nonatomic, strong) NSURLSession *session;
// 下载模型字典 key = url
@property (nonatomic, strong) NSMutableDictionary *downloadingModelDic;
// 下载中的模型
@property (nonatomic, strong) NSMutableArray *waitingDownloadModels;
// 等待中的模型
@property (nonatomic, strong) NSMutableArray *downloadingModels;
// 回调代理的队列
@property (strong, nonatomic) NSOperationQueue *queue;

@property (nonatomic, strong) spHeaderSignOrToken *headerSignToken;

@property (nonatomic, strong) NSString * strBucket;

@property (nonatomic, strong) NSString * strObj;

@end

@implementation spDownLoadDataManager

#pragma mark - getter

+ (spDownLoadDataManager *)manager:(NSString*)accesskey
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
        _maxDownloadCount = 1;
        _resumeDownloadFIFO = YES;
        _isBatchDownload = NO;
        _headerSignToken = [[spHeaderSignOrToken alloc] initWithData:accesskey withSecretKey:secretkey];
    }
    return self;
}

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
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.queue];
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

// 下载文件信息plist路径
- (NSString *)fileSizePathWithDownloadModel:(spDownloadModel *)downloadModel
{
    return [downloadModel.downloadDirectory stringByAppendingPathComponent:@"downloadsFileSize.plist"];
}

// 下载model字典
- (NSMutableDictionary *)downloadingModelDic
{
    if (!_downloadingModelDic) {
        _downloadingModelDic = [NSMutableDictionary dictionary];
    }
    return _downloadingModelDic;
}

// 等待下载model队列
- (NSMutableArray *)waitingDownloadModels
{
    if (!_waitingDownloadModels) {
        _waitingDownloadModels = [NSMutableArray array];
    }
    return _waitingDownloadModels;
}

// 正在下载model队列
- (NSMutableArray *)downloadingModels
{
    if (!_downloadingModels) {
        _downloadingModels = [NSMutableArray array];
    }
    return _downloadingModels;
}


#pragma mark - downlaod

// 开始下载
- (spDownloadModel *)startDownloadURLString:(NSString *)URLString bucket:(NSString *)bucket
                                        obj:(NSString*)obj  toDestinationPath:(NSString *)destinationPath progress:(spDownloadProgressBlock)progress state:(spDownloadStateBlock)state
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
    
    [self startWithDownloadModel:downloadModel bucket:bucket obj:obj progress:progress state:state];
    
    return downloadModel;
}

- (void)startWithDownloadModel:(spDownloadModel *)downloadModel bucket:(NSString *)bucket
                           obj:(NSString*)obj progress:(spDownloadProgressBlock)progress state:(spDownloadStateBlock)state
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
    
    // 验证是否已经下载文件
    if ([self isDownloadCompletedWithDownloadModel:downloadModel]) {
        downloadModel.state = spDownloadStateCompleted;
        [self downloadModel:downloadModel didChangeState:spDownloadStateCompleted filePath:downloadModel.filePath error:nil];
        return;
    }
    
    // 验证是否存在
    if (downloadModel.task && downloadModel.task.state == NSURLSessionTaskStateRunning) {
        downloadModel.state = spDownloadStateRunning;
        [self downloadModel:downloadModel didChangeState:spDownloadStateRunning filePath:nil error:nil];
        return;
    }
    
    [self resumeWithDownloadModel:downloadModel bucket:bucket obj:obj];
}

// 自动下载下一个等待队列任务
- (void)willResumeNextWithDowloadModel:(spDownloadModel *)downloadModel
{
    if (_isBatchDownload) {
        return;
    }
    
    @synchronized (self) {
        [self.downloadingModels removeObject:downloadModel];
        // 还有未下载的
        if (self.waitingDownloadModels.count > 0) {
            if(_resumeDownloadFIFO){
                [self resumeWithDownloadModel:self.waitingDownloadModels.firstObject bucket:_strBucket obj:_strObj];
            }else{
                [self resumeWithDownloadModel:self.waitingDownloadModels.lastObject bucket:_strBucket obj:_strObj];
            }
        }
    }
}

// 是否开启下载等待队列任务
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
        NSString *URLString = downloadModel.downloadURL;
        
        // 创建请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        
        NSString * path = [NSString stringWithFormat:@"%@/%@",bucket,obj];
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"application/x-www-form-urlencoded", @"content_type", path, @"url",@"GET", @"http_method",nil];
        NSDictionary* headers = [_headerSignToken generateHeaders:@"GET" params:params isJson:false];
        [request setAllHTTPHeaderFields:headers];
        [request setHTTPMethod:@"GET"];
        
        // 设置请求头
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", [self fileSizeWithDownloadModel:downloadModel]];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        // 创建流
        downloadModel.stream = [NSOutputStream outputStreamToFileAtPath:downloadModel.filePath append:YES];
        
        downloadModel.downloadDate = [NSDate date];
        self.downloadingModelDic[downloadModel.downloadURL] = downloadModel;
        // 创建一个Data任务
        downloadModel.task = [self.session dataTaskWithRequest:request];
        downloadModel.task.taskDescription = URLString;
    }
    
    _strBucket = bucket;
    _strObj = obj;
    
    [downloadModel.task resume];
    
    downloadModel.state = spDownloadStateRunning;
    [self downloadModel:downloadModel didChangeState:spDownloadStateRunning filePath:nil error:nil];
}

// 暂停下载
- (void)suspendWithDownloadModel:(spDownloadModel *)downloadModel
{
    if (!downloadModel.manualCancle) {
        downloadModel.manualCancle = YES;
        [downloadModel.task cancel];
    }
}

// 取消下载
- (void)cancleWithDownloadModel:(spDownloadModel *)downloadModel
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
    
    if (downloadModel.state != spDownloadStateCompleted && downloadModel.state != spDownloadStateFailed){
        [downloadModel.task cancel];
    }
}

#pragma mark - delete file

- (void)deleteFileWithDownloadModel:(spDownloadModel *)downloadModel
{
    if (!downloadModel || !downloadModel.filePath) {
        return;
    }
    
    // 文件是否存在
    if ([self.fileManager fileExistsAtPath:downloadModel.filePath]) {
        
        // 删除任务
        downloadModel.task.taskDescription = nil;
        [downloadModel.task cancel];
        downloadModel.task = nil;
        
        // 删除流
        if (downloadModel.stream.streamStatus > NSStreamStatusNotOpen && downloadModel.stream.streamStatus < NSStreamStatusClosed) {
            [downloadModel.stream close];
        }
        downloadModel.stream = nil;
        // 删除沙盒中的资源
        NSError *error = nil;
        [self.fileManager removeItemAtPath:downloadModel.filePath error:&error];
        if (error) {
            NSLog(@"delete file error %@",error);
        }
        
        [self removeDownLoadingModelForURLString:downloadModel.downloadURL];
        // 删除资源总长度
        if ([self.fileManager fileExistsAtPath:[self fileSizePathWithDownloadModel:downloadModel]]) {
            @synchronized (self) {
                NSMutableDictionary *dict = [self fileSizePlistWithDownloadModel:downloadModel];
                [dict removeObjectForKey:downloadModel.downloadURL];
                [dict writeToFile:[self fileSizePathWithDownloadModel:downloadModel] atomically:YES];
            }
        }
    }
}

- (void)deleteAllFileWithDownloadDirectory:(NSString *)downloadDirectory
{
    if (!downloadDirectory) {
        downloadDirectory = self.downloadDirectory;
    }
    if ([self.fileManager fileExistsAtPath:downloadDirectory]) {
        
        // 删除任务
        for (spDownloadModel *downloadModel in [self.downloadingModelDic allValues]) {
            if ([downloadModel.downloadDirectory isEqualToString:downloadDirectory]) {
                // 删除任务
                downloadModel.task.taskDescription = nil;
                [downloadModel.task cancel];
                downloadModel.task = nil;
                
                // 删除流
                if (downloadModel.stream.streamStatus > NSStreamStatusNotOpen && downloadModel.stream.streamStatus < NSStreamStatusClosed) {
                    [downloadModel.stream close];
                }
                downloadModel.stream = nil;
            }
        }
        // 删除沙盒中所有资源
        [self.fileManager removeItemAtPath:downloadDirectory error:nil];
    }
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
    long long fileSize = [self fileSizeInCachePlistWithDownloadModel:downloadModel];
    if (fileSize > 0 && fileSize == [self fileSizeWithDownloadModel:downloadModel]) {
        return YES;
    }
    return NO;
}

// 当前下载进度
- (spDownloadProgress *)progessWithDownloadModel:(spDownloadModel *)downloadModel
{
    spDownloadProgress *progress = [[spDownloadProgress alloc]init];
    progress.totalBytesExpectedToWrite = [self fileSizeInCachePlistWithDownloadModel:downloadModel];
    progress.totalBytesWritten = MIN([self fileSizeWithDownloadModel:downloadModel], progress.totalBytesExpectedToWrite);
    progress.progress = progress.totalBytesExpectedToWrite > 0 ? 1.0*progress.totalBytesWritten/progress.totalBytesExpectedToWrite : 0;
    
    return progress;
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

//  创建缓存目录文件
- (void)createDirectory:(NSString *)directory
{
    if (![self.fileManager fileExistsAtPath:directory]) {
        [self.fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

// 获取文件大小
- (long long)fileSizeWithDownloadModel:(spDownloadModel *)downloadModel{
    NSString *filePath = downloadModel.filePath;
    if (![self.fileManager fileExistsAtPath:filePath]) return 0;
    return [[self.fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
}

// 获取plist保存文件大小
- (long long)fileSizeInCachePlistWithDownloadModel:(spDownloadModel *)downloadModel
{
    NSDictionary *downloadsFileSizePlist = [NSDictionary dictionaryWithContentsOfFile:[self fileSizePathWithDownloadModel:downloadModel]];
    return [downloadsFileSizePlist[downloadModel.downloadURL] longLongValue];
}

// 获取plist文件内容
- (NSMutableDictionary *)fileSizePlistWithDownloadModel:(spDownloadModel *)downloadModel
{
    NSMutableDictionary *downloadsFileSizePlist = [NSMutableDictionary dictionaryWithContentsOfFile:[self fileSizePathWithDownloadModel:downloadModel]];
    if (!downloadsFileSizePlist) {
        downloadsFileSizePlist = [NSMutableDictionary dictionary];
    }
    return downloadsFileSizePlist;
}

- (void)removeDownLoadingModelForURLString:(NSString *)URLString
{
    [self.downloadingModelDic removeObjectForKey:URLString];
}

#pragma mark - NSURLSessionDelegate

/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    spDownloadModel *downloadModel = [self downLoadingModelForURLString:dataTask.taskDescription];
    if (!downloadModel) {
        return;
    }
    
    // 创建目录
    [self createDirectory:_downloadDirectory];
    [self createDirectory:downloadModel.downloadDirectory];
    
    // 打开流
    [downloadModel.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    long long totalBytesWritten =  [self fileSizeWithDownloadModel:downloadModel];
    long long totalBytesExpectedToWrite = totalBytesWritten + dataTask.countOfBytesExpectedToReceive;
    
    downloadModel.progress.resumeBytesWritten = totalBytesWritten;
    downloadModel.progress.totalBytesWritten = totalBytesWritten;
    downloadModel.progress.totalBytesExpectedToWrite = totalBytesExpectedToWrite;
    
    // 存储总长度
    @synchronized (self) {
        NSMutableDictionary *dic = [self fileSizePlistWithDownloadModel:downloadModel];
        dic[downloadModel.downloadURL] = @(totalBytesExpectedToWrite);
        [dic writeToFile:[self fileSizePathWithDownloadModel:downloadModel] atomically:YES];
    }
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    spDownloadModel *downloadModel = [self downLoadingModelForURLString:dataTask.taskDescription];
    if (!downloadModel || downloadModel.state == spDownloadStateSuspended) {
        return;
    }
    // 写入数据
    [downloadModel.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    downloadModel.progress.bytesWritten = data.length;
    downloadModel.progress.totalBytesWritten += downloadModel.progress.bytesWritten;
    downloadModel.progress.progress  = MIN(1.0, 1.0*downloadModel.progress.totalBytesWritten/downloadModel.progress.totalBytesExpectedToWrite);
    
    // 时间
    NSTimeInterval downloadTime = -1 * [downloadModel.downloadDate timeIntervalSinceNow];
    downloadModel.progress.speed = (downloadModel.progress.totalBytesWritten - downloadModel.progress.resumeBytesWritten) / downloadTime;
    
    int64_t remainingContentLength = downloadModel.progress.totalBytesExpectedToWrite - downloadModel.progress.totalBytesWritten;
    downloadModel.progress.remainingTime = ceilf(remainingContentLength / downloadModel.progress.speed);
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self downloadModel:downloadModel updateProgress:downloadModel.progress];
    });
}

/**
 * 请求完毕（成功|失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    spDownloadModel *downloadModel = [self downLoadingModelForURLString:task.taskDescription];
    
    if (!downloadModel) {
        return;
    }
    
    // 关闭流
    [downloadModel.stream close];
    downloadModel.stream = nil;
    downloadModel.task = nil;
    
    [self removeDownLoadingModelForURLString:downloadModel.downloadURL];

    if (downloadModel.manualCancle) {
        // 暂停下载
        dispatch_async(dispatch_get_main_queue(), ^(){
            downloadModel.manualCancle = NO;
            downloadModel.state = spDownloadStateSuspended;
            [self downloadModel:downloadModel didChangeState:spDownloadStateSuspended filePath:nil error:nil];
            [self willResumeNextWithDowloadModel:downloadModel];
        });
    }else if (error){
        // 下载失败
        dispatch_async(dispatch_get_main_queue(), ^(){
            downloadModel.state = spDownloadStateFailed;
            [self downloadModel:downloadModel didChangeState:spDownloadStateFailed filePath:nil error:error];
            [self willResumeNextWithDowloadModel:downloadModel];
        });
    }else if ([self isDownloadCompletedWithDownloadModel:downloadModel]) {
        // 下载完成
        dispatch_async(dispatch_get_main_queue(), ^(){
            downloadModel.state = spDownloadStateCompleted;
            [self downloadModel:downloadModel didChangeState:spDownloadStateCompleted filePath:downloadModel.filePath error:nil];
            [self willResumeNextWithDowloadModel:downloadModel];
        });
    }else {
        // 下载完成
         dispatch_async(dispatch_get_main_queue(), ^(){
             downloadModel.state = spDownloadStateCompleted;
             [self downloadModel:downloadModel didChangeState:spDownloadStateCompleted filePath:downloadModel.filePath error:nil];
             [self willResumeNextWithDowloadModel:downloadModel];
         });
    }
}

@end
