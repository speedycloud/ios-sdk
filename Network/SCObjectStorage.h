//
//  Network.h
//  SpeedyCloud
//
//  Created by 郭煌 on 2017/4/17.
//  Copyright © 2017年 SpeedyCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCObjectStorage: NSObject

@property NSString *BASE_SERVER;
@property NSString *ACCESS_KEY;
@property NSString *SECRET_KEY;
@property (nonatomic, assign) BOOL SHOW_DEBUG;

//+ (void)get:(NSString *)string block:(AFNData)block BLOCK:(AFNDataa)BLOCK;

- (id) initWithKeySecret: (NSString *)access secret:(NSString *)secret;

// 创建存储桶
- (NSString *) createBucket:(NSString *)bucket;
// 删除删除存储桶
- (NSString *) deleteBucket:(NSString *)bucket;
//修改存储桶的权限
- (NSString *) updateBucketAcl:(NSString *)bucket acl:(NSString *)acl;
// 查询桶存储桶的权限
- (NSString *) queryBucketAcl:(NSString *)bucket;
// 设置存储桶的版本控制
- (NSString *) setBucketVersioning:(NSString *)bucket status:(NSString *)status;
// 在存储桶内创建对象（上传小文件，小于100M）
- (NSString *) createObject:(NSString *)bucket key:(NSString *)key data:(NSString *)data;
// 删除存储桶内的对象
- (NSString *) deleteObject:(NSString *)bucket key:(NSString *)key;
// 删除存储桶内指定版本的对象
- (NSString *) deleteObjectVersion:(NSString *)bucket key:(NSString *)key version:(NSString *)version;
// 修改存储桶内对象的权限
- (NSString *) updateObjectAcl:(NSString *)bucket key:(NSString *)key acl:(NSString *)acl;
// 修改存储桶内指定版本的对象的权限
- (NSString *) updateObjectVersionAcl:(NSString *)bucket key:(NSString *)key version:(NSString *)version acl:(NSString *)acl;
// 查询存储桶内的对象的权限
- (NSString *) queryObjectAcl:(NSString *)bucket key:(NSString *)key;
// 查询存储桶内所有对象
- (NSString *) queryAllObjects:(NSString *)bucket;
// 查询存储桶的版本信息
- (NSString *) queryBucketVersioning:(NSString *)bucket;
// 查询存储桶内所有对象的版本信息
- (NSString *) queryObjectVersions:(NSString *)bucket;
// 下载存储桶内的对象
-(NSString *) downloadObject:(NSString *)bucket key:(NSString *)key;
// 大数据上传(步骤一)
-(NSString *) uploadBigObjectStep1:(NSString *)bucket key:(NSString *)key;
// 大数据上传(步骤二)
-(NSString *) uploadBigObjectStep2:(NSString *)bucket key:(NSString *)key step:(NSUInteger *)step uploadId:(NSString *)uploadId data:(NSData *)data;
//  大数据上传(步骤三)
-(NSString *) uploadBigObject3:(NSString *)bucket key:(NSString *)key uploadId:(NSString *)uploadId data:(NSData *)data;
@end
