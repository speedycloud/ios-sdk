//
//  spObjUpLoadSDK.m
//  spObjUpLoadSDK
//
//  Created by YanBo on 2018/3/12.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spObjUpLoadManager.h"
#import "spConfigure.h"
#import "spSessionManager.h"
#import "spFormUpload.h"
#import "spAsyncRun.h"
#import "spFileDelegate.h"
#import "spResumeUpload.h"
#import "spFile.h"
#import "spResponseInfo.h"
#import "GenerateExternalUrl.h"

#define SDKVERSION @"1.0.1"

@interface spObjUpLoadManager ()
@property (nonatomic) id<spHttpDelegate> httpManager;
@property (nonatomic) spConfigure *config;
@property (nonatomic) GenerateExternalUrl *genExUrl;
@end

@implementation spObjUpLoadManager

+ (instancetype)sharedInstanceWithConfigure:(spConfigure *)config {
    static spObjUpLoadManager *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithConfigure:config];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    return [self initWithConfigure:nil];
}

- (instancetype)initWithConfigure:(spConfigure *)config {
    if (self = [super init]) {
        if (config == nil) {
            config = [spConfigure build:^(spConfigureBuilder *builder){
            }];
        }
        _config = config;
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
        _httpManager = [[spSessionManager alloc] initParams:_config.uploadAccessKey secretKey:_config.uploadSecretKey];
        _genExUrl = [[GenerateExternalUrl alloc] initWithData:_config.uploadAccessKey withSecretKey:_config.uploadSecretKey];
#endif
    }
    return self;
}

- (NSString*)getSDKVersion{
    return [NSString stringWithFormat:@"SDKVersion:%@",SDKVERSION];
}

- (void)putFileInternal:(id<spFileDelegate>)file
                 bucket:(NSString *)bucket
                    obj:(NSString *)obj
               complete:(spUpCompletionHandler)completionHandler
                 option:(spUpLoadOption *)option {
    @autoreleasepool {
//        QNUpToken *t = [QNUpToken parse:token];
        //        t.access = @"123456";
        //        t.bucket = @"312654";
        //        t.token = @"6666";
        
        //        if (t == nil) {
        //            QNAsyncRunInMain(^{
        //                completionHandler([QNResponseInfo responseInfoWithInvalidToken:@"invalid token"], key, nil);
        //            });
        //            return;
        //        }
        //
        //        [_config.zone preQuery:t on:^(int code) {
        //            if (code != 0) {
        //                QNAsyncRunInMain(^{
        //                    completionHandler([QNResponseInfo responseInfoWithInvalidToken:@"get zone failed"], key, nil);
        //                });
        //                return;
        //            }
        spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            [file close];
            spAsyncRunInMain(^{
                completionHandler(info, key, resp);
            });
        };
        //
        //            if ([file size] <= _config.putThreshold) {
        //                NSData *data = [file readAll];
        //                [self putData:data key:key token:token complete:complete option:option];
        //                return;
        //            }
        
        NSString *recorderKey = obj;
//        if (_config.recorder != nil && _config.recorderKeyGen != nil) {
//            recorderKey = @"";//_config.recorderKeyGen(key, [file path]);
//        }
        
        NSLog(@"recorder %@", _config.recorder);
        
        spResumeUpload *up = [[spResumeUpload alloc]
                              initWithFile:file
                              withBucket:bucket
                              withKey:obj
                              withCompletionHandler:complete
                              withOption:option
                              withRecorder:_config.recorder
                              withRecorderKey:recorderKey
                              withHttpManager:_httpManager
                              withConfiguration:_config];
        spAsyncRun(^{
            [up run];
        });
        //        }];
    }
}

///////////////////////////////////////////// 重新定义对外接口/////////////////////////////////////////////
// 查询桶权限
- (void)queryBucketAcl:(NSString *)bucket
           complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@?acl",bucket];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:nil
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up get];
    });
}
// 创建桶
- (void)createBucket:(NSString *)bucket
            complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@",bucket];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];

    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:nil
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up put];
    });
}
// 删除桶
- (void)deleteBucket:(NSString *)bucket
           complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@",bucket];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:nil
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up del];
    });
}

// 修改桶权限
- (void)updateBucketAcl:(NSString *)bucket
               complete:(spUpCompletionHandler)completionHandler
                 option:(spUpLoadOption *)option{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@?acl",bucket];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:option
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up put];
    });
}

//设置桶版本控制
- (void)setBucketVersion:(NSString *)bucket
                 version:(NSString *)version
                complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@?versioning",bucket];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    if(![version isEqualToString:@"Enabled"] && ![version isEqualToString:@"Suspended"]){
        NSDictionary *resp = nil;
        spResponseInfo *info = [[spResponseInfo alloc] init:400 withReqId:nil withETAG:nil withXLog:nil withXVia:nil withHost:nil withIp:nil withDuration:0 withBody:nil];
        complete(info,nil,resp);
    }
        
    NSString *body =[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<VersioningConfiguration xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">\n<Status>%@</Status>\n</VersioningConfiguration>", version];
    NSData *data = [body dataUsingEncoding:NSASCIIStringEncoding];
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:data
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:nil
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up put];
    });
}

// 删除桶内对象
- (void)deleteObj:(NSString *)bucket
              obj:(NSString *)obj
            complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@/%@",bucket,obj];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:nil
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up del];
    });
}

// 删除桶内指定版本的对象
- (void)deleteObjForVersion:(NSString *)bucket
                        obj:(NSString *)obj
                  versionId:(NSString *)versionId
                   complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@/%@?versionId=%@",bucket,obj,versionId];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:nil
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up del];
    });
}

// 修改对象权限
- (void)updateObj:(NSString *)bucket
              obj:(NSString *)obj
         complete:(spUpCompletionHandler)completionHandler
           option:(spUpLoadOption *)option{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@/%@?acl",bucket,obj];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:option
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up put];
    });
}

// 查询对象权限
- (void)queryObj:(NSString *)bucket
              obj:(NSString *)obj
         complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@/%@",bucket,obj];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:nil
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up get];
    });
}

// 查询桶内所有对象
- (void)queryAllObj:(NSString *)bucket
        complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@",bucket];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:nil
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up get];
    });
}

// 查询桶版本信息
- (void)queryBucketVersion:(NSString *)bucket
                  complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@?versioning",bucket];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:nil
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up get];
    });
}

// 查询桶内所有对象版本信息
- (void)queryAllObjVersion:(NSString *)bucket
                  complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@?versions",bucket];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    if(_config.bResJsonType){
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    
    spFormUpload *up = [[spFormUpload alloc]
                        initWithData:nil
                        withUrl:url
                        withPath:path
                        withKey:nil
                        withCompletionHandler:complete
                        withOption:nil
                        withHttpManager:_httpManager
                        withConfiguration:_config];
    spAsyncRun(^{
        [up get];
    });
}

// 上传文件
-(void)uploadFile:(NSString *)bucket
                      obj:(NSString *)obj
                 filePath:(NSString *)filepath
         complete:(spUpCompletionHandler)completionHandler
           option:(spUpLoadOption *)option{
    @autoreleasepool {
        NSError *error = nil;
        __block spFile *file = [[spFile alloc] init:filepath error:&error];
        if (error) {
            spAsyncRunInMain(^{
                spResponseInfo *info = [spResponseInfo responseInfoWithNetError:error host:nil duration:0];
                completionHandler(info, obj, nil);
            });
            return;
        }
        [self putFileInternal:file bucket:bucket obj:obj complete:completionHandler option:option];
    }
}

// 获取外链
-(NSString *)getExternalUrl:(NSString *)bucket
                  obj:(NSString *)obj
                contentType:(NSString*)contentType
                 expireDate:(NSInteger)timeStamp{
    
    NSString * path = [NSString stringWithFormat:@"%@/%@",bucket,obj];
    NSString * url = [[NSString alloc] initWithFormat:@"%@/%@",_config.baseServer,path];
    NSString * method = @"GET";
    
    if(contentType == nil || contentType == @""){
        contentType = @"application/x-www-form-urlencoded";
    }
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:contentType, @"content_type", path, @"url",@"GET", @"http_method",nil];
    
    if(_config.bResJsonType){
        [params setValue:@"json" forKey:@"Sc-Resp-Content-Type"];
        if([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&ctype=json", url];
        } else {
            url = [NSString stringWithFormat:@"%@?ctype=json", url];
        }
    }
    NSDictionary *headers = [[_httpManager getHeaderSign] generateHeaders:method params:params isJson:TRUE];

    return [_genExUrl generateExternalUrl:method expireDuration:timeStamp hostName:@"oss-cn-shanghai.speedycloud.org" bucket:bucket keyPath:obj];
}

// 下载文件
-(void)downloadFile:(NSString *)bucket
              obj:(NSString *)obj
         complete:(spUpCompletionHandler)completionHandler{
    spUpCompletionHandler complete = ^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        spAsyncRunInMain(^{
            completionHandler(info, key, resp);
        });
    };
    
    NSLog(@"recorder %@", _config.recorder);
    
    spResumeUpload *up = [[spResumeUpload alloc]
                          initWithFile:nil
                          withBucket:bucket
                          withKey:obj
                          withCompletionHandler:complete
                          withOption:nil
                          withRecorder:_config.recorder
                          withRecorderKey:obj
                          withHttpManager:_httpManager
                          withConfiguration:_config];
    spAsyncRun(^{
        [up run];
    });
}

@end
