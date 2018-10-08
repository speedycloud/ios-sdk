//
//  spHeaderSignOrToken.h
//  spObjSDK
//
//  Created by YanBo on 2018/3/20.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface spHeaderSignOrToken : NSObject

@property (nonatomic,strong) NSString * accessKey;
@property (nonatomic,strong) NSString * secretKey;

- (instancetype)initWithData:(NSString *)accessKey
               withSecretKey:(NSString*)secretKey;

-(NSDictionary *) generateHeaders:(NSString *)method params:(NSDictionary *)params isJson:(BOOL)isJson;
    
@end
