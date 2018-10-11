//
//  spFormUpload.m
//  spObjSDK
//
//  Created by YanBo on 2018/3/19.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spConfigure.h"
#import "spFormUpload.h"
#import "spResponseInfo.h"

@interface spFormUpload ()

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) id<spHttpDelegate> httpManager;
@property (nonatomic) int retryTimes;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) spUpLoadOption *option;
@property (nonatomic, strong) spUpCompletionHandler complete;
@property (nonatomic, strong) spConfigure *config;
@property (nonatomic) float previousPercent;

@property (nonatomic, strong) NSString *access; //AK

@end

@implementation spFormUpload

- (instancetype)initWithData:(NSData *)data
                     withUrl:(NSString *)url
                    withPath:(NSString *)path
                     withKey:(NSString *)key
       withCompletionHandler:(spUpCompletionHandler)block
                  withOption:(spUpLoadOption *)option
             withHttpManager:(id<spHttpDelegate>)http
           withConfiguration:(spConfigure *)config {
    if (self = [super init]) {
        _data = data;
        _url = url;
        _path = path;
        _key = key;
        _option = option != nil ? option : [spUpLoadOption defaultOptions];
        _complete = block;
        _httpManager = http;
        _config = config;
        _previousPercent = 0;
    }
    return self;
}

- (void)post {
//    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSString *fileName = _key;
//    if (_key) {
//        parameters[@"key"] = _key;
//    } else {
//        fileName = @"?";
//    }
    
    NSString *path = [[NSString alloc] initWithFormat:@"%@?acl", _config.uploadBucket];
    NSString *method = @"POST";
    NSDictionary* parameters = nil;
    if(_data != nil && _data.length >0){
        NSString *length = [NSString stringWithFormat:@"%lu", _data.length];
        parameters = [[NSDictionary alloc] initWithObjectsAndKeys:_option.mimeType, @"content_type", length, @"content_length", path, @"url",
                                    method, @"http_method",nil];
    }else{
        parameters = [[NSDictionary alloc] initWithObjectsAndKeys:_option.mimeType, @"content_type", path, @"url",method, @"http_method",nil];
    }


    spInternalProgressBlock p = ^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float percent = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
        if (percent > 0.95) {
            percent = 0.95;
        }
        if (percent > _previousPercent) {
            _previousPercent = percent;
        } else {
            percent = _previousPercent;
        }
        _option.progressHandler(_key, percent);
    };
    // TODO test 查询桶权限
    __block NSString *upHost = [NSString stringWithFormat:@"%@/%@", _config.baseServer, path];
    spCompleteBlock complete = ^(spResponseInfo *info, NSDictionary *resp) {
        if (info.isOK) {
            _option.progressHandler(_key, 1.0);
        }
//        if (info.isOK || !info.couldRetry) {
//            _complete(info, _key, resp);
//            return;
//        }
        if (_option.cancellationSignal()) {
//            _complete([spResponseInfo cancel], _key, nil);
            return;
        }
        __block NSString *nextHost = upHost;
//        if (info.isConnectionBroken || info.needSwitchServer) {
//            nextHost = [_config.zone up:_token isHttps:_config.useHttps frozenDomain:nextHost];
//        }
        spCompleteBlock retriedComplete = ^(spResponseInfo *info, NSDictionary *resp) {
            if (info.isOK) {
                _option.progressHandler(_key, 1.0);
            }
            if (info.isOK || !info.couldRetry) {
                _complete(info, _key, resp);
                return;
            }
            if (_option.cancellationSignal()) {
                _complete([spResponseInfo cancel], _key, nil);
                return;
            }
            NSString *thirdHost = nextHost;
//            if (info.isConnectionBroken || info.needSwitchServer) {
//                thirdHost = [_config.zone up:_token isHttps:_config.useHttps frozenDomain:nextHost];
//            }
            spCompleteBlock thirdComplete = ^(spResponseInfo *info, NSDictionary *resp) {
                if (info.isOK) {
                    _option.progressHandler(_key, 1.0);
                }
                _complete(info, _key, resp);
            };
            [_httpManager multipartPost:thirdHost
                               withData:_data
                             withParams:parameters
                           withFileName:fileName
                           withMimeType:_option.mimeType
                      withCompleteBlock:thirdComplete
                      withProgressBlock:p
                        withCancelBlock:_option.cancellationSignal
                             withAccess:_access];
        };
        [_httpManager multipartPost:nextHost
                           withData:_data
                         withParams:parameters
                       withFileName:fileName
                       withMimeType:_option.mimeType
                  withCompleteBlock:retriedComplete
                  withProgressBlock:p
                    withCancelBlock:_option.cancellationSignal
                         withAccess:_access];
    };
    [_httpManager multipartPost:upHost
                       withData:_data
                     withParams:parameters
                   withFileName:fileName
                   withMimeType:_option.mimeType
              withCompleteBlock:complete
              withProgressBlock:p
                withCancelBlock:_option.cancellationSignal
                     withAccess:_access];
}

-(void)put{
    // 传输参数
    NSString *method = @"PUT";
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[@"content_type"] = _option.mimeType;
    parameters[@"url"] = _path;
    parameters[@"http_method"] = method;
    [parameters addEntriesFromDictionary:_option.params];
    
    [_httpManager simpleUp:_url withData:_data withParams:parameters withbResJson:_config.bResJsonType withCompleteBlock:^(spResponseInfo *info, NSDictionary *resp) {
        if (info.isOK) {
            _option.progressHandler(_key, 1.0);
        }
        if (_option.cancellationSignal()) {
            _complete([spResponseInfo cancel], _key, nil);
            return;
        }
        _complete(info, _key, resp);
    }];
}

-(void)get{
    // 传输参数
    NSString *method = @"GET";
    NSDictionary* parameters = [[NSDictionary alloc] initWithObjectsAndKeys:_option.mimeType, @"content_type", _path, @"url",method, @"http_method",nil];
    
    [_httpManager simpleUp:_url withData:nil withParams:parameters withbResJson:_config.bResJsonType withCompleteBlock:^(spResponseInfo *info, NSDictionary *resp) {
        if (info.isOK) {
            _option.progressHandler(_key, 1.0);
        }
        if (_option.cancellationSignal()) {
            _complete([spResponseInfo cancel], _key, nil);
            return;
        }
        _complete(info, _key, resp);
    }];
}

-(void)del{
    // 传输参数
    NSString *method = @"DELETE";
    NSDictionary* parameters = [[NSDictionary alloc] initWithObjectsAndKeys:_option.mimeType, @"content_type", _path, @"url",method, @"http_method",nil];
    
    [_httpManager simpleUp:_url withData:nil withParams:parameters withbResJson:_config.bResJsonType withCompleteBlock:^(spResponseInfo *info, NSDictionary *resp) {
        if (info.isOK) {
            _option.progressHandler(_key, 1.0);
        }
        if (_option.cancellationSignal()) {
            _complete([spResponseInfo cancel], _key, nil);
            return;
        }
        _complete(info, _key, resp);
    }];
}


@end
