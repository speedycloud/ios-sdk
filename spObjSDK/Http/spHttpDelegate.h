//
//  spHttpDelegate.h
//  spObjSDK
//
//  Created by YanBo on 2018/3/15.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class spResponseInfo;

typedef void (^spInternalProgressBlock)(long long totalBytesWritten, long long totalBytesExpectedToWrite);
typedef void (^spCompleteBlock)(spResponseInfo *info, NSDictionary *resp);
typedef BOOL (^spCancelBlock)(void);

/**
 *    Http 客户端接口
 */
@protocol spHttpDelegate <NSObject>

- (void)multipartPost:(NSString *)url
             withData:(NSData *)data
           withParams:(NSDictionary *)params
         withFileName:(NSString *)key
         withMimeType:(NSString *)mime
    withCompleteBlock:(spCompleteBlock)completeBlock
    withProgressBlock:(spInternalProgressBlock)progressBlock
      withCancelBlock:(spCancelBlock)cancelBlock
           withAccess:(NSString *)access;

- (void)multipartUp:(NSString *)url
         withMethod:(NSString *)method
    withData:(NSData *)data
  withParams:(NSDictionary *)params
 withHeaders:(NSDictionary *)headers
withCompleteBlock:(spCompleteBlock)completeBlock
withProgressBlock:(spInternalProgressBlock)progressBlock
withCancelBlock:(spCancelBlock)cancelBlock
  withAccess:(NSString *)access;

- (void)simpleUp:(NSString *)url
        withData:(NSData *)data
      withParams:(NSDictionary *)params
    withbResJson:(BOOL)bJson
withCompleteBlock:(spCompleteBlock)completeBlock;

@end
