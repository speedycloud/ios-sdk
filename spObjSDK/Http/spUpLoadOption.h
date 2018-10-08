//
//  spUpLoadOption.h
//  spObjSDK
//
//  Created by YanBo on 2018/3/16.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *    上传进度回调函数
 *
 *    @param key     上传时指定的存储key
 *    @param percent 进度百分比
 */
typedef void (^spUpProgressHandler)(NSString *key, float percent);

/**
 *    上传中途取消函数
 *
 *    @return 如果想取消，返回True, 否则返回No
 */
typedef BOOL (^spUpCancellationSignal)(void);

@interface spUpLoadOption : NSObject

/**
 *    用于上传回调通知的自定义参数
 */
@property (copy, nonatomic, readonly) NSDictionary *params;

/**
 *    进度回调函数
 */
@property (copy, readonly) spUpProgressHandler progressHandler;

/**
 *    中途取消函数
 */
@property (copy, readonly) spUpCancellationSignal cancellationSignal;

/**
 *    指定文件的mime类型
 */
@property (copy, nonatomic, readonly) NSString *mimeType;


/**
 *    可选参数的初始化方法
 *
 *    @param mimeType     mime类型
 *    @param progress     进度函数
 *    @param params       自定义服务器回调参数
 *    @param check        是否进行crc检查
 *    @param cancellation 中途取消函数
 *
 *    @return 可选参数类实例
 */
- (instancetype)initWithMime:(NSString *)mimeType
             progressHandler:(spUpProgressHandler)progress
                      params:(NSDictionary *)params
//                    checkCrc:(BOOL)check
          cancellationSignal:(spUpCancellationSignal)cancellation;

- (instancetype)initWithProgressHandler:(spUpProgressHandler)progress;

/**
 *    内部使用，默认的参数实例
 *
 *    @return 可选参数类实例
 */
+ (instancetype)defaultOptions;

@end
