//
//  spSessionManager.m
//  spObjSDK
//
//  Created by YanBo on 2018/3/15.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spSessionManager.h"
#import "spResponseInfo.h"
#import "spHeaderSignOrToken.h"
#import "spAsyncRun.h"

@interface spProgessDelegate : NSObject <NSURLSessionDataDelegate>
@property (nonatomic, strong) spInternalProgressBlock progressBlock;
@property (nonatomic, strong) NSURLSessionUploadTask *task;
@property (nonatomic, strong) spCancelBlock cancelBlock;
- (instancetype)initWithProgress:(spInternalProgressBlock)progressBlock;
@end

static BOOL needRetry(NSHTTPURLResponse *httpResponse, NSError *error) {
    if (error != nil) {
        return error.code < -1000;
    }
    if (httpResponse == nil) {
        return YES;
    }
    int status = (int)httpResponse.statusCode;
    return status >= 500 && status < 600 && status != 579;
}

@implementation spProgessDelegate
- (instancetype)initWithProgress:(spInternalProgressBlock)progressBlock {
    if (self = [super init]) {
        _progressBlock = progressBlock;
    }
    
    return self;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    
    if (_progressBlock) {
        _progressBlock(totalBytesSent, totalBytesExpectedToSend);
    }
    if (_cancelBlock && _cancelBlock()) {
        [_task cancel];
    }
}

@end


@interface spSessionManager ()
//@property UInt32 timeout;
//@property (nonatomic, strong) QNUrlConvert converter;
//@property bool noProxy;
//@property (nonatomic, strong) NSDictionary *proxyDict;
//@property (nonatomic) QNDnsManager *dns;
@property (nonatomic, strong) spHeaderSignOrToken * headerSignToken;
@property (nonatomic, strong) NSOperationQueue *delegateQueue;
@end

@implementation spSessionManager

+ (spResponseInfo *)buildResponseInfo:(NSHTTPURLResponse *)response
                            withError:(NSError *)error
                         withDuration:(double)duration
                         withResponse:(NSData *)body
                             withHost:(NSString *)host
                               withIp:(NSString *)ip {
    spResponseInfo *info;
    
    if (response) {
        int status = (int)[response statusCode];
        NSDictionary *headers = [response allHeaderFields];
        NSString *strETag = headers[@"Etag"];
        if(strETag.length == 0){
            strETag = headers[@"ETag"];
        }
        NSString *reqId = headers[@"X-Reqid"];
        NSString *xlog = headers[@"X-Log"];
        NSString *xvia = headers[@"X-Via"];
        if (xvia == nil) {
            xvia = headers[@"X-Px"];
        }
        if (xvia == nil) {
            xvia = headers[@"Fw-Via"];
        }
        info = [[spResponseInfo alloc] init:status withReqId:reqId withETAG:strETag withXLog:xlog withXVia:xvia withHost:host withIp:ip withDuration:duration withBody:body];
    } else {
        info = [spResponseInfo responseInfoWithNetError:error host:host duration:duration];
    }
    return info;
}

- (instancetype)initWithProxy:(NSDictionary *)proxyDict
                      timeout:(UInt32)timeout
                    accessKey:(NSString*)accesskey
                    secretKey:(NSString*)secretkey{
    if (self = [super init]) {
//        if([self isBlankString:config.uploadAccesskey] ||
//           [self isBlankString:config.uploadSecretkey]){
            _headerSignToken = [[spHeaderSignOrToken alloc] initWithData:accesskey withSecretKey:secretkey];
//        }else{
//            _headerSignToken = [[spHeaderSignOrToken alloc] initWithData:config.uploadAccesskey withSecretKey:config.uploadSecretkey];
//        }
        
        if (proxyDict != nil) {
//            _noProxy = NO;
//            _proxyDict = proxyDict;
        } else {
//            _noProxy = YES;
        }
        _delegateQueue = [[NSOperationQueue alloc] init];
//        _timeout = timeout;
//        _converter = converter;
//        _dns = dns;
    }
    
    return self;
}

-(spHeaderSignOrToken *)getHeaderSign{
    return _headerSignToken;
}

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

- (instancetype)initParams:(NSString*)accesskey
                 secretKey:(NSString*)secretkey{
    return [self initWithProxy:nil timeout:60 accessKey:accesskey secretKey:secretkey];
}


- (void)sendRequest:(NSMutableURLRequest *)request
  withCompleteBlock:(spCompleteBlock)completeBlock
  withProgressBlock:(spInternalProgressBlock)progressBlock
    withCancelBlock:(spCancelBlock)cancelBlock
           withData:(NSData *)data
         withAccess:(NSString *)access {
    __block NSDate *startTime = [NSDate date];
    NSString *domain = request.URL.host;
    NSString *u = request.URL.absoluteString;
    NSURL *url = request.URL;
    NSArray *ips = nil;

    [self sendRequest2:request withCompleteBlock:completeBlock withProgressBlock:progressBlock withCancelBlock:cancelBlock withData:data withIpArray:ips withIndex:0 withDomain:domain withRetryTimes:3 withStartTime:startTime withAccess:access];
}

- (void)sendRequest2:(NSMutableURLRequest *)request
   withCompleteBlock:(spCompleteBlock)completeBlock
   withProgressBlock:(spInternalProgressBlock)progressBlock
     withCancelBlock:(spCancelBlock)cancelBlock
            withData:(NSData *)data
         withIpArray:(NSArray *)ips
           withIndex:(int)index
          withDomain:(NSString *)domain
      withRetryTimes:(int)times
       withStartTime:(NSDate *)startTime
          withAccess:(NSString *)access {
//    NSURL *url = request.URL;
    __block NSString *ip = nil;
    __block NSData * outData = data;
    //    if (ips != nil) {
    //        ip = [ips objectAtIndex:(index % ips.count)];
    //        NSString *path = url.path;
    //        if (path == nil || [@"" isEqualToString:path]) {
    //            path = @"/";
    //        }
    //        url = buildUrl(ip, url.port, path);
    //        [request setValue:domain forHTTPHeaderField:@"Host"];
    //    }
//    request.URL = url;
    [request setTimeoutInterval:60];
//    [request setValue:[[QNUserAgent sharedInstance] getUserAgent:access] forHTTPHeaderField:@"User-Agent"];
//    [request setValue:nil forHTTPHeaderField:@"Accept-Language"];
    if (progressBlock == nil) {
        progressBlock = ^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        };
    }
    spInternalProgressBlock progressBlock2 = ^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        progressBlock(totalBytesWritten, totalBytesExpectedToWrite);
    };
    __block spProgessDelegate *delegate = [[spProgessDelegate alloc] initWithProgress:progressBlock];
    delegate.progressBlock = progressBlock2;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    if (_proxyDict) {
//        configuration.connectionProxyDictionary = _proxyDict;
//    }
    __block NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:_delegateQueue];
    
    NSData * nsData = @"";
    if(data != nil){
        nsData = data;
    }
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromData:nsData completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
    
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        double duration = [[NSDate date] timeIntervalSinceDate:startTime];
        spResponseInfo *info;
        NSDictionary *resp = nil;
        if (/*_converter != nil && _noProxy && */(index + 1 < 3 || times > 0) && needRetry(httpResponse, error)) {
            [self sendRequest2:request withCompleteBlock:completeBlock withProgressBlock:progressBlock withCancelBlock:cancelBlock withData:outData withIpArray:ips withIndex:index + 1 withDomain:domain withRetryTimes:times - 1 withStartTime:startTime withAccess:access];
            return;
        }
        if (error == nil) {
            info = [spSessionManager buildResponseInfo:httpResponse withError:nil withDuration:duration withResponse:data withHost:domain withIp:ip];
            if (info.isOK) {
                NSError *tmp;
                resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&tmp];
            }
        } else {
            info = [spSessionManager buildResponseInfo:httpResponse withError:error withDuration:duration withResponse:data withHost:domain withIp:ip];
        }
        delegate.task = nil;
        delegate.cancelBlock = nil;
        delegate.progressBlock = nil;
        completeBlock(info, resp);
        [session finishTasksAndInvalidate];
    }];
    delegate.task = uploadTask;
    delegate.cancelBlock = cancelBlock;
    [uploadTask resume];
}

- (void)multipartPost:(NSString *)url
             withData:(NSData *)data
           withParams:(NSDictionary *)params
         withFileName:(NSString *)key
         withMimeType:(NSString *)mime
    withCompleteBlock:(spCompleteBlock)completeBlock
    withProgressBlock:(spInternalProgressBlock)progressBlock
      withCancelBlock:(spCancelBlock)cancelBlock
           withAccess:(NSString *)access {
//    NSURL *URL = [[NSURL alloc] initWithString:url];
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:url]];
    
    NSDictionary* headers = [_headerSignToken generateHeaders:@"POST" params:params isJson:false];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPMethod:@"POST"];
    //    if (params) {
    //        [request setValuesForKeysWithDictionary:params];
    //    }
    if(data != nil){
        [request setHTTPBody:data];
    }
    
    [self sendRequest:request withCompleteBlock:completeBlock withProgressBlock:progressBlock withCancelBlock:cancelBlock withData:nil
           withAccess:access];
}

- (void)multipartUp:(NSString *)url
         withMethod:(NSString *)method
           withData:(NSData *)data
         withParams:(NSDictionary *)params
        withHeaders:(NSDictionary *)headers
  withCompleteBlock:(spCompleteBlock)completeBlock
  withProgressBlock:(spInternalProgressBlock)progressBlock
    withCancelBlock:(spCancelBlock)cancelBlock
         withAccess:(NSString *)access {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:url]];
    
    if(headers == nil){
        headers = [_headerSignToken generateHeaders:method params:params isJson:true];
    }
    [request setAllHTTPHeaderFields:headers];

    [request setHTTPMethod:method];
//    if (params) {
//        [request setValuesForKeysWithDictionary:params];
//    }
    if(data != nil){
        [request setHTTPBody:data];
    }
    
    spAsyncRun(^{
        [self sendRequest:request
        withCompleteBlock:completeBlock
        withProgressBlock:progressBlock
          withCancelBlock:cancelBlock
                 withData:data
               withAccess:access];
    });
}

- (void)simpleUp:(NSString *)url
        withData:(NSData *)data
      withParams:(NSDictionary *)params
    withbResJson:(BOOL)bJson
withCompleteBlock:(spCompleteBlock)completeBlock {
    spAsyncRun(^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:url]];
        
        NSString * method = @"GET"; // 默认
        for (NSString *key in params) {
            if([key isEqualToString:@"http_method"]){
                method = [NSString stringWithFormat:@"%@",params[key]];
            }
        }
        
        NSDictionary* headers = [_headerSignToken generateHeaders:method params:params isJson:bJson];
        [request setAllHTTPHeaderFields:headers];
        [request setHTTPMethod:method];
        
        if(data != nil){
            [request setHTTPBody:data];
        }
        
        NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSData *s = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *resp = nil;
            spResponseInfo *info;
            if (error == nil) {
                info = [spSessionManager buildResponseInfo:httpResponse withError:nil withDuration:0 withResponse:s withHost:@"" withIp:@""];
                if (info.isOK) {
                    NSError *jsonError;
                    id unMarshel = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                    if (jsonError) {
                        info = [spSessionManager buildResponseInfo:httpResponse withError:jsonError withDuration:0 withResponse:s withHost:@"" withIp:@""];
                    } else if ([unMarshel isKindOfClass:[NSDictionary class]]) {
                        resp = unMarshel;
                    }
                }
            } else {
                info = [spSessionManager buildResponseInfo:httpResponse withError:error withDuration:0 withResponse:s withHost:@"" withIp:@""];
            }
            
            completeBlock(info, resp);
        }];
        [dataTask resume];
        
    });
}

@end
