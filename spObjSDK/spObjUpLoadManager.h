//
//  spObjUpLoadSDK.h
//  spObjUpLoadSDK
//
//  Created by YanBo on 2018/3/12.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "spUpLoadOption.h"

@class spResponseInfo;
@class spConfigure;

/**
 *    上传完成后的回调函数
 *
 *    @param info 上下文信息，包括状态码，错误值
 *    @param key  上传时指定的key，原样返回
 *    @param resp 上传成功会返回文件信息，失败为nil; 可以通过此值是否为nil 判断上传结果
 */
typedef void (^spUpCompletionHandler)(spResponseInfo *info, NSString *key, NSDictionary *resp);

/**
 管理上传的类，可以生成一次，持续使用，不必反复创建。
 */
@interface spObjUpLoadManager : NSObject

/**
 *    默认构造方法，没有持久化记录
 *
 *    @return 上传管理类实例
 */
 - (instancetype)init;

/**
 *    使用配置信息生成上传实例
 *
 *    @param config           配置信息
 *
 *    @return 上传管理类实例
 */
- (instancetype)initWithConfigure:(spConfigure *)config;

/**
 *    方便使用的单例方法
 *
 *    @param config           配置信息
 *
 *    @return 上传管理类实例
 */
+ (instancetype)sharedInstanceWithConfigure:(spConfigure *)config;

// 获取当前sdk版本号
- (NSString *)getSDKVersion;
///////////////////////////////////////////// 定义对外接口/////////////////////////////////////////////
/**
 *    创建桶
 *
 *    @param bucket            创建bucket的名称
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)createBucket:(NSString *)bucket
            complete:(spUpCompletionHandler)completionHandler;

/**
 *    查询桶权限
 *
 *    @param bucket            查询bucket的名称
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)queryBucketAcl:(NSString *)bucket
            complete:(spUpCompletionHandler)completionHandler;

/**
 *    删除桶
 *
 *    @param bucket            删除bucket的名称
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)deleteBucket:(NSString *)bucket
           complete:(spUpCompletionHandler)completionHandler;

/**
 *    修改桶权限
 *
 *    @param bucket            修改bucket的名称
 *    @param completionHandler 上传完成后的回调函数
 *    @param option            其他参数设置 progress params等
 */
- (void)updateBucketAcl:(NSString *)bucket
               complete:(spUpCompletionHandler)completionHandler
                 option:(spUpLoadOption *)option;

/**
 *    修改桶权限
 *
 *    @param bucket            修改bucket的名称
 *    @param completionHandler 上传完成后的回调函数
 *    @param option            上传时传入的可选参数
 */
- (void)updateBucketAcl:(NSString *)bucket
               complete:(spUpCompletionHandler)completionHandler
                 option:(spUpLoadOption *)option;
/*
*    设置桶版本控制
*
*    @param bucket            设置bucket的名称
*    @param data              待上传的数据
*    @param completionHandler 上传完成后的回调函数
*    @param option            上传时传入的可选参数
*/
- (void)setBucketVersion:(NSString *)bucket
                 version:(NSString *)version
                complete:(spUpCompletionHandler)completionHandler;

/**
 *    删除桶内对象
 *
 *    @param bucket            删除bucket的名称
 *    @param obj               删除bucket的对象的名称
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)deleteObj:(NSString *)bucket
                 obj:(NSString *)obj
            complete:(spUpCompletionHandler)completionHandler;

/**
 *    删除桶内指定版本的对象
 *
 *    @param bucket            删除bucket的名称
 *    @param obj               删除bucket的对象的名称
 *    @param versionId         删除bucket的指定对象的版本Id
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)deleteObjForVersion:(NSString *)bucket
              obj:(NSString *)obj
        versionId:(NSString *)versionId
         complete:(spUpCompletionHandler)completionHandler;

/**
 *    修改对象权限
 *
 *    @param bucket            删除bucket的名称
 *    @param obj               删除bucket的对象的名称
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)updateObj:(NSString *)bucket
              obj:(NSString *)obj
         complete:(spUpCompletionHandler)completionHandler
           option:(spUpLoadOption *)option;

/**
 *    查询对象权限
 *
 *    @param bucket            bucket的名称
 *    @param obj               bucket的对象的名称
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)queryObj:(NSString *)bucket
              obj:(NSString *)obj
         complete:(spUpCompletionHandler)completionHandler;

/**
 *    查询桶内所有对象版本信息
 *
 *    @param bucket            bucket的名称
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)queryAllObj:(NSString *)bucket
        complete:(spUpCompletionHandler)completionHandler;

/**
 *    查询桶版本信息
 *
 *    @param bucket            bucket的名称
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)queryBucketVersion:(NSString *)bucket
           complete:(spUpCompletionHandler)completionHandler;

/**
 *    查询桶内所有对象版本信息
 *
 *    @param bucket            bucket的名称
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)queryAllObjVersion:(NSString *)bucket
                  complete:(spUpCompletionHandler)completionHandler;

/**
 *    上传文件(一律分片上传)
 *
 *    @param bucket            bucket的名称
 *    @param obj               obj的名称
 *    @param completionHandler 上传完成后的回调函数
 *    @param option            上传时传入的可选参数
 */
- (void)uploadFile:(NSString *)bucket
               obj:(NSString *)obj
          filePath:(NSString *)filepath
          complete:(spUpCompletionHandler)completionHandler
            option:(spUpLoadOption*)option;

/**
 *    获取外链
 *
 *    @param bucket            bucket的名称
 *    @param obj               obj的名称
 *    @param contentType       content_type
 *    @param timeStamp         过期时间戳
 */
- (NSString *)getExternalUrl:(NSString *)bucket
                         obj:(NSString *)obj
                 contentType:(NSString*)contentType
                  expireDate:(NSInteger)timeStamp;

/**
 *    下载文件
 *
 *    @param bucket            bucket的名称
 *    @param obj               obj的名称
 *    @param completionHandler 上传完成后的回调函数
 */
- (void)downloadFile:(NSString *)bucket
               obj:(NSString *)obj
          complete:(spUpCompletionHandler)completionHandler;


@end
