//
//  spSessionManager.h
//  spObjSDK
//
//  Created by YanBo on 2018/3/15.
//  Copyright © 2018年 YanBo. All rights reserved.
//
#import "spHttpDelegate.h"
#import "spHeaderSignOrToken.h"
#import <Foundation/Foundation.h>

@interface spSessionManager : NSObject <spHttpDelegate>

- (instancetype)initParams:(NSString*)accesskey
secretKey:(NSString*)secretkey;

// 应该用于断点续传 用于所有put
- (void)multipartPost:(NSString *)url
             withData:(NSData *)data
           withParams:(NSDictionary *)params
         withFileName:(NSString *)key
         withMimeType:(NSString *)mime
    withCompleteBlock:(spCompleteBlock)completeBlock
    withProgressBlock:(spInternalProgressBlock)progressBlock
      withCancelBlock:(spCancelBlock)cancelBlock
           withAccess:(NSString *)access;

// 用于大文件上传
- (void)multipartUp:(NSString *)url
         withMethod:(NSString *)method
    withData:(NSData *)data
  withParams:(NSDictionary *)params
 withHeaders:(NSDictionary *)headers
withCompleteBlock:(spCompleteBlock)completeBlock
withProgressBlock:(spInternalProgressBlock)progressBlock
withCancelBlock:(spCancelBlock)cancelBlock
  withAccess:(NSString *)access;

// 所有指令请求
- (void)simpleUp:(NSString *)url
withData:(NSData *)data
withParams:(NSDictionary *)params
withbResJson:(BOOL)bJson
withCompleteBlock:(spCompleteBlock)completeBlock;

-(spHeaderSignOrToken *)getHeaderSign;

@end
