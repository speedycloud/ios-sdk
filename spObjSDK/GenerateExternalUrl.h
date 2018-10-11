//
//  GenerateExternalUrl.h
//  spObjSDK
//
//  Created by YanBo on 2018/10/10.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GenerateExternalUrl : NSObject

@property (nonatomic,strong) NSString * accessKey;
@property (nonatomic,strong) NSString * secretKey;

- (instancetype)initWithData:(NSString *)accessKey
               withSecretKey:(NSString*)secretKey;

-(NSString *) generateExternalUrl:(NSString *)method
                   expireDuration:(int32_t)expireDuration
                         hostName:hostname
                           bucket:bucket
                          keyPath:keyPath;

@end

NS_ASSUME_NONNULL_END
