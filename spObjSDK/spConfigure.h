//
//  spConfigure.h
//  spObjSDK
//
//  Created by YanBo on 2018/3/14.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spRecorderDelegate.h"
#import <Foundation/Foundation.h>

/**
 *    断点上传时的分块大小
 */
extern const UInt32 upSpBlockSize;

@class spConfigureBuilder;
/**
 *    Builder block
 *
 *    @param builder builder实例
 */
typedef void (^spConfigureBuilderBlock)(spConfigureBuilder *builder);

@interface spConfigure : NSObject

@property (nonatomic, readonly) NSString * baseServer;
@property (nonatomic, readonly) NSString * uploadBucket;
@property (nonatomic, readonly) NSString * uploadKey;
@property (nonatomic, readonly) NSString * uploadAccessKey;
@property (nonatomic, readonly) NSString * uploadSecretKey;
@property (nonatomic, readonly) BOOL bResJsonType;
@property (nonatomic, readonly) id<spRecorderDelegate> recorder;
@property (nonatomic, readonly) spRecorderKeyGenerator recorderKeyGen;

/**
 *    上传失败的重试次数
 */
@property (readonly) UInt32 retryMax;
/**
 *    断点上传时的分片大小
 */
@property (readonly) UInt32 chunkSize;

+ (instancetype)build:(spConfigureBuilderBlock)block;

@end

@interface spConfigureBuilder : NSObject

@property (nonatomic, strong) NSString * baseServer;
@property (nonatomic, strong) NSString * uploadBucket;
@property (nonatomic, strong) NSString * uploaKey;
@property (nonatomic, strong) NSString * uploadAccessKey;
@property (nonatomic, strong) NSString * uploadSecretKey;
@property (nonatomic) BOOL bResJsonType;
@property (nonatomic, strong) id<spRecorderDelegate> recorder;
@property (nonatomic, strong) spRecorderKeyGenerator recorderKeyGen;

/**
 *    上传失败的重试次数
 */
@property (assign) UInt32 retryMax;

/**
 *    断点上传时的分片大小
 */
@property (assign) UInt32 chunkSize;

@end
