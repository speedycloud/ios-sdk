//
//  SPResponseInfo.h
//  spObjSDK
//
//  Created by YanBo on 2018/3/14.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *    中途取消的状态码
 */
extern const int eSpRequestCancelled;

/**
 *    网络错误状态码
 */
extern const int eSpNetworkError;

/**
 *    错误参数状态码
 */
extern const int eSpInvalidArgument;

/**
 *    0 字节文件或数据
 */
extern const int eSpZeroDataSize;

/**
 *    错误token状态码
 */
extern const int eSpInvalidToken;

/**
 *    读取文件错误状态码
 */
extern const int eSpFileError;

/**
 *    桶权限
 */
extern const NSString * strSpBucketAclPrivate;
extern const NSString * strSpBucketAclPublicR;
extern const NSString * strSpBucketAclPublicRW;

/**
 *    桶版本控制enum
 */
extern const NSString * strSpBucketVersionEnabled;
extern const NSString * strSpBucketVersionSuspended;

@interface spResponseInfo : NSObject

/**
 *    是否需要重试，内部使用
 */
@property (nonatomic, readonly) BOOL couldRetry;

/**
 *    成功的请求
 */
@property (nonatomic, readonly, getter=isOK) BOOL ok;
/**
 *    工厂函数，内部使用
 *
 *    @return 取消的实例
 */
+ (instancetype)cancel;

/**
 *    状态码
 */
@property (readonly) int statusCode;

/**
 *    业务相关的请求ID，用来跟踪请求信息，如果使用过程中出现问题，请反馈此ID
 */
@property (nonatomic, copy, readonly) NSString *reqId;


/**
 *    上传分片文件ETag值
 */
@property (nonatomic, copy, readonly) NSString *eTag;

/**
 *    错误信息，出错时请反馈此记录
 */
@property (nonatomic, copy, readonly) NSError *error;

/**
 *    工厂函数，内部使用
 *
 *    @param error 错误信息
 *    @param host 服务器域名
 *    @param duration 请求完成时间，单位秒
 *
 *    @return 网络错误实例
 */
+ (instancetype)responseInfoWithNetError:(NSError *)error
                                    host:(NSString *)host
                                duration:(double)duration;

/**
 *    构造函数
 *
 *    @param status 状态码
 *    @param reqId  业务相关id
 *    @param etag   分片上传记录
 *    @param xlog   服务器记录
 *    @param body   服务器返回内容
 *    @param host   服务器域名
 *    @param duration 请求完成时间，单位秒
 *
 *    @return 实例
 */
- (instancetype)init:(int)status
           withReqId:(NSString *)reqId
            withETAG:(NSString *)etag
            withXLog:(NSString *)xlog
            withXVia:(NSString *)xvia
            withHost:(NSString *)host
              withIp:(NSString *)ip
        withDuration:(double)duration
            withBody:(NSData *)body;

@end
