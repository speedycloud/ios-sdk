//
//  spResumeUpload.m
//  spObjSDK
//
//  Created by YanBo on 2018/3/20.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spResumeUpload.h"
#import "spConfigure.h"
//#import "QNCrc32.h"
#import "spRecorderDelegate.h"
#import "spResponseInfo.h"
#import "spObjUpLoadManager.h"
//#import "QNUploadOption+Private.h"
//#import "QNUrlSafeBase64.h"

typedef void (^task)(void);

NSString * const NSUpLoad_Step1 = @"step1";
NSString * const NSUpLoad_Step2 = @"step2";
NSString * const NSUpLoad_Step3 = @"step3";


@interface spResumeUpload ()

@property (nonatomic, strong) id<spHttpDelegate> httpManager;
@property UInt32 size;
@property (nonatomic) int retryTimes;
@property (nonatomic, strong) NSString *bucket;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *uploadId;
@property (nonatomic, strong) NSString *recorderKey;
@property (nonatomic) NSDictionary *headers;
@property (nonatomic, strong) spUpLoadOption *option;
//@property (nonatomic, strong) spUpToken *token;
@property (nonatomic, strong) spUpCompletionHandler complete;
@property (nonatomic, strong) NSMutableArray *contexts;

@property int64_t modifyTime;
@property (nonatomic, strong) id<spRecorderDelegate> recorder;

@property (nonatomic, strong) spConfigure *config;

@property UInt32 chunkCrc;

@property (nonatomic, strong) id<spFileDelegate> file;

//@property (nonatomic, strong) NSArray *fileAry;

@property (nonatomic) float previousPercent;

@property (nonatomic, strong) NSString *access; //AK

- (void)makeBlock:(NSString *)uphost
           offset:(UInt32)offset
        blockSize:(UInt32)blockSize
        chunkSize:(UInt32)chunkSize
         progress:(spInternalProgressBlock)progressBlock
         complete:(spCompleteBlock)complete;

- (void)putChunk:(NSString *)uphost
          offset:(UInt32)offset
            size:(UInt32)size
         context:(NSString *)context
        progress:(spInternalProgressBlock)progressBlock
        complete:(spCompleteBlock)complete;

- (void)makeFile:(NSString *)uphost
        complete:(spCompleteBlock)complete;

@end

@implementation spResumeUpload

- (instancetype)initWithFile:(id<spFileDelegate>)file
                  withBucket:(NSString *)bucket
                     withKey:(NSString *)key
//                   withToken:(QNUpToken *)token
       withCompletionHandler:(spUpCompletionHandler)block
                  withOption:(spUpLoadOption *)option
                withRecorder:(id<spRecorderDelegate>)recorder
             withRecorderKey:(NSString *)recorderKey
             withHttpManager:(id<spHttpDelegate>)http
           withConfiguration:(spConfigure *)config;
{
    if (self = [super init]) {
        _file = file;
        _size = (UInt32)[file size];
        _bucket = bucket;
        _key = key;
        _uploadId = nil;
//        NSString *tokenUp = [NSString stringWithFormat:@"UpToken %@", token.token];
        _option = option != nil ? option : [spUpLoadOption defaultOptions];
        _complete = block;
        _headers = nil;
        _recorder = recorder;
        _httpManager = http;
        _modifyTime = [file modifyTime];
        _recorderKey = recorderKey;
        _contexts = [[NSMutableArray alloc] initWithCapacity:(_size + upSpBlockSize - 1) / upSpBlockSize];
        _config = config;

//        _token = token;
        _previousPercent = 0;

//        _access = token.access;
    }
    return self;
}

// save json value
//{
//    "size":filesize,
//    "offset":lastSuccessOffset,
//    "modify_time": lastFileModifyTime,
//    "contexts": contexts
//}

- (BOOL) isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

- (void)record:(UInt32)offset {
    NSString *key = self.recorderKey;
    if (offset == 0 || _recorder == nil || key == nil || [key isEqualToString:@""]) {
        return;
    }
    NSNumber *n_size = @(self.size);
    NSNumber *n_offset = @(offset);
    NSNumber *n_time = [NSNumber numberWithLongLong:_modifyTime];
    NSMutableDictionary *rec = [NSMutableDictionary dictionaryWithObjectsAndKeys:n_size, @"size", n_offset, @"offset", n_time, @"modify_time", _contexts, @"contexts",_uploadId,@"uploadId", nil];

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:rec options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"up record json error %@ %@", key, error);
        return;
    }
    error = [_recorder set:key data:data];
    if (error != nil) {
        NSLog(@"up record set error %@ %@", key, error);
    }
}

- (void)removeRecord {
    if (_recorder == nil) {
        return;
    }
    [_recorder del:self.recorderKey];
}

- (UInt32)recoveryFromRecord {
    NSString *key = self.recorderKey;
    if (_recorder == nil || key == nil || [key isEqualToString:@""]) {
        return 0;
    }

    NSData *data = [_recorder get:key];
    if (data == nil) {
        return 0;
    }

    NSError *error;
    NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    if (error != nil) {
        NSLog(@"recovery error %@ %@", key, error);
        [_recorder del:self.key];
        return 0;
    }
    NSNumber *n_offset = info[@"offset"];
    NSNumber *n_size = info[@"size"];
    NSNumber *time = info[@"modify_time"];
    NSArray *contexts = info[@"contexts"];
    NSString *uploadId = info[@"uploadId"];
    if (n_offset == nil || n_size == nil || time == nil || contexts == nil || uploadId == nil) {
        return 0;
    }

    UInt32 offset = [n_offset unsignedIntValue];
    UInt32 size = [n_size unsignedIntValue];
    if (offset > size || size != self.size) {
        return 0;
    }
    UInt64 t = [time unsignedLongLongValue];
    if (t != _modifyTime) {
        NSLog(@"modify time changed %llu, %llu", t, _modifyTime);
        return 0;
    }
    _contexts = [[NSMutableArray alloc] initWithArray:contexts copyItems:true];
    if(offset > 0){
        _uploadId = uploadId;
    }
    return offset;
}

- (void)nextTask:(UInt32)offset retriedTimes:(int)retried host:(NSString *)host step:(NSString *)strStep {
    if (self.option.cancellationSignal()) {
        self.complete([spResponseInfo cancel], self.key, nil);
        return;
    }

    if (offset == self.size) {
        spCompleteBlock completionHandler = ^(spResponseInfo *info, NSDictionary *resp) {
            if (info.isOK) {
                [self removeRecord];
                self.option.progressHandler(self.key, 1.0);
            } else if (info.couldRetry && retried < _config.retryMax) {
                [self nextTask:offset retriedTimes:retried + 1 host:host step:nil];
                return;
            }
            self.complete(info, self.key, resp);
        };
        [self makeFile:host complete:completionHandler];
        return;
    }

    UInt32 chunkSize = [self calcPutSize:offset];
    spInternalProgressBlock progressBlock = ^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float percent = (float)(offset + totalBytesWritten) / (float)self.size;
        if (percent > 0.95) {
            percent = 0.95;
        }
        if (percent > _previousPercent) {
            _previousPercent = percent;
        } else {
            percent = _previousPercent;
        }
        self.option.progressHandler(self.key, percent);
    };

    spCompleteBlock completionHandler = ^(spResponseInfo *info, NSDictionary *resp) {
        if (info.statusCode != 200) {
            if([strStep isEqualToString:NSUpLoad_Step1]){
                // 获取uploadid
                self.complete(info, self.key, resp);
                return ;
            }
            NSLog(@"code:%d error:%@",info.statusCode,info.error.description);
            if (info.statusCode == 701) {
                [self nextTask:(offset / upSpBlockSize) * upSpBlockSize retriedTimes:0 host:host step:NSUpLoad_Step2];
                return;
            }
            if (retried >= _config.retryMax || !info.couldRetry) {
                self.complete(info, self.key, resp);
                return;
            }

            NSString *nextHost = host;
//            if (info.isConnectionBroken || info.needSwitchServer) {
//                nextHost = [_config.zone up:_token isHttps:_config.useHttps frozenDomain:nextHost];
//            }

            [self nextTask:offset retriedTimes:retried + 1 host:nextHost step:NSUpLoad_Step2];
            return;
        }
        
        if(info.statusCode == 200 ){
            if([strStep isEqualToString:NSUpLoad_Step1]){
                NSDictionary * nextDic = nil;
                for (NSString * key in resp) {
                    if ([key isEqualToString:@"InitiateMultipartUploadResult"]){
                        nextDic = resp[key];
                    }
                }
                if (nextDic != nil) {
                    [nextDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
                        if ([key isEqualToString:@"UploadId"] && ![obj isEqualToString:@""]) {
                            _uploadId = obj;
                        }
                    }];
                }
                
                [self nextTask:offset retriedTimes:retried host:host step:NSUpLoad_Step2];
                return;
            }
            if([strStep isEqualToString:NSUpLoad_Step2]){
                NSString *ctx = info.eTag;
                //        NSNumber *crc = resp[@"crc32"];
                if (ctx == nil || ctx.length == 0) {
                    [self nextTask:offset retriedTimes:retried host:host step:NSUpLoad_Step2];
                    return;
                }
                _contexts[offset / upSpBlockSize] = ctx;
                [self record:offset + chunkSize];
                NSLog(@"size = %d offset= %d",self.size,offset + chunkSize);
                [self nextTask:offset + chunkSize retriedTimes:retried host:host step:NSUpLoad_Step2];
                return;
            }
        }

//        if (resp == nil) {
//            [self nextTask:offset retriedTimes:retried host:host step:strUpLoad_Step2];
//            return;
//        }

        
    };
    
    if([strStep isEqualToString:NSUpLoad_Step1]){
        [self getUploadId:host progress:progressBlock complete:completionHandler];
        return ;
    }
    if (offset < [self size] && offset % upSpBlockSize == 0) {
        UInt32 blockSize = [self calcBlockSize:offset];
        [self makeBlock:host offset:offset blockSize:blockSize chunkSize:blockSize progress:progressBlock complete:completionHandler];
        return;
    }
//    if(offset == [self size]){
//        [self putChunk:host offset:offset size:0 contextArray:_contexts progress:progressBlock complete:completionHandler];
//    }
}

- (UInt32)calcPutSize:(UInt32)offset {
    UInt32 left = self.size - offset;
    return left < _config.chunkSize ? left : _config.chunkSize;
}

- (UInt32)calcBlockSize:(UInt32)offset {
    UInt32 left = self.size - offset;
    return left < upSpBlockSize ? left : upSpBlockSize;
}

- (void)makeBlock:(NSString *)uphost
           offset:(UInt32)offset
        blockSize:(UInt32)blockSize
        chunkSize:(UInt32)chunkSize
         progress:(spInternalProgressBlock)progressBlock
         complete:(spCompleteBlock)complete {
    NSData *data = [self.file read:offset size:chunkSize];
    UInt32 chunkCount = offset / upSpBlockSize;
    NSString * urlEx = [[NSString alloc] initWithFormat:@"?partNumber=%d&uploadId=%@",chunkCount+1,_uploadId];
    NSLog(@"%@",urlEx);
    NSString *url = [[NSString alloc] initWithFormat:@"%@/%@/%@%@", uphost,_bucket,_key,urlEx];
//    _chunkCrc = [QNCrc32 data:data];
    [self put:url withUrlExtends:urlEx withData:data withCompleteBlock:complete withProgressBlock:progressBlock];
}

- (void)getUploadId:(NSString *)uphost
         progress:(spInternalProgressBlock)progressBlock
         complete:(spCompleteBlock)complete {
    NSString * urlEx = @"?uploads";
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@/%@%@", uphost,_bucket,_key,urlEx];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    //    _chunkCrc = [QNCrc32 data:data];
    [self post:url withUrlExtends:urlEx withData:nil withCompleteBlock:complete withProgressBlock:progressBlock];
}

- (void)putChunk:(NSString *)uphost
          offset:(UInt32)offset
            size:(UInt32)size
         contextArray:(NSMutableArray *)contextArray
        progress:(spInternalProgressBlock)progressBlock
        complete:(spCompleteBlock)complete {
    NSString *bodyStr = @"<CompleteMultipartUpload>\n";
    for (int i = 0; i < contextArray.count; i++)
    {
        NSString * str = [contextArray objectAtIndex:i];
        NSString *strPart = [NSString stringWithFormat:@"  <Part>\n    <PartNumber>%d</PartNumber>\n    <ETag>%@</ETag>\n  </Part>\n",i+1,str];
        bodyStr =[NSString stringWithFormat:@"%@%@", bodyStr,strPart];
        NSLog(@"str %@",str);
    }
    bodyStr =[NSString stringWithFormat:@"%@</CompleteMultipartUpload>", bodyStr];
    NSLog(@"bodystr:%@",bodyStr);
//    NSData *data = [self.file read:offset size:size];
//    UInt32 chunkOffset = offset % upSpBlockSize;
    NSString * urlEx = [[NSString alloc] initWithFormat:@"%@/%@?uploadId=%@",_bucket,_key,_uploadId];
    NSLog(@"%@",urlEx);
    NSString *url = [[NSString alloc] initWithFormat:@"%@/%@", uphost,urlEx];
    
    NSData * data = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
//    _chunkCrc = [QNCrc32 data:data];
    [self post:url withUrlExtends:urlEx withData:data withCompleteBlock:complete withProgressBlock:progressBlock];
}

- (void)makeFile:(NSString *)uphost
        complete:(spCompleteBlock)complete {
    NSString * urlEx = [[NSString alloc] initWithFormat:@"?uploadId=%@",_uploadId];
    NSLog(@"%@",urlEx);
    NSString *url = [[NSString alloc] initWithFormat:@"%@/%@/%@%@", uphost,_bucket,_key, urlEx];
    NSString *bodyStr = @"<CompleteMultipartUpload>\n";
    for (int i = 0; i < _contexts.count; i++)
    {
        NSString * str = [_contexts objectAtIndex:i];
        NSString *strPart = [NSString stringWithFormat:@"  <Part>\n    <PartNumber>%d</PartNumber>\n    <ETag>%@</ETag>\n  </Part>\n",i+1,str];
        bodyStr =[NSString stringWithFormat:@"%@%@", bodyStr,strPart];
        NSLog(@"str %@",str);
    }
    bodyStr =[NSString stringWithFormat:@"%@</CompleteMultipartUpload>", bodyStr];
    NSLog(@"bodystr:%@",bodyStr);

    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[bodyStr dataUsingEncoding:NSUTF8StringEncoding]];
    [self post:url withUrlExtends:urlEx withData:postData withCompleteBlock:complete withProgressBlock:nil];
}

#pragma mark - 处理文件路径
- (NSString *)fileBaseName {
    return [[_file path] lastPathComponent];
}

- (void)post:(NSString *)url
        withUrlExtends:(NSString *)urlExtends
             withData:(NSData *)data
    withCompleteBlock:(spCompleteBlock)completeBlock
    withProgressBlock:(spInternalProgressBlock)progressBlock {
    
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@%@", _bucket,_key,urlExtends];
    NSString *method = @"POST";
    NSMutableDictionary* parameters = nil;
    if(data != nil && data.length >0){
        NSString *length = [NSString stringWithFormat:@"%lu", data.length];
        parameters = [[NSMutableDictionary alloc] initWithObjectsAndKeys:_option.mimeType, @"content_type", length, @"content_length", path, @"url",
                      method, @"http_method",nil];
    }else{
        parameters = [[NSMutableDictionary alloc] initWithObjectsAndKeys:_option.mimeType, @"content_type", path, @"url",method, @"http_method",nil];
    }
    
    if(_config.bResJsonType){
        [parameters setValue:@"json" forKey:@"Sc-Resp-Content-Type"];
    }
    
    [_httpManager multipartUp:url withMethod:method withData:data withParams:parameters withHeaders:_headers withCompleteBlock:completeBlock withProgressBlock:progressBlock withCancelBlock:_option.cancellationSignal withAccess:_access];
}

- (void)put:(NSString *)url
 withUrlExtends:(NSString *)urlExtends
    withData:(NSData *)data
withCompleteBlock:(spCompleteBlock)completeBlock
withProgressBlock:(spInternalProgressBlock)progressBlock {
    
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@%@", _bucket,_key,urlExtends];
    NSString *method = @"PUT";
    NSString *length = [NSString stringWithFormat:@"%lu", data.length];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:_option.mimeType, @"content_type", length, @"content_length", path, @"url",
                            method, @"http_method",nil];
    
    if(_config.bResJsonType){
        [params setValue:@"json" forKey:@"Sc-Resp-Content-Type"];
    }
    
    [_httpManager multipartUp:url withMethod:method withData:data withParams:params withHeaders:_headers withCompleteBlock:completeBlock withProgressBlock:progressBlock withCancelBlock:_option.cancellationSignal withAccess:_access];
}

- (void)run {
    @autoreleasepool {
        UInt32 offset = [self recoveryFromRecord];
        [self nextTask:offset retriedTimes:0 host:_config.baseServer step:offset == 0 ? NSUpLoad_Step1 :NSUpLoad_Step2];
    }
}

@end
