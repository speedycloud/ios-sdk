//
//  GenerateExternalUrl.m
//  spObjSDK
//
//  Created by YanBo on 2018/10/10.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#import "GenerateExternalUrl.h"

static NSTimeInterval _clockskew = 0.0;

@implementation GenerateExternalUrl

- (instancetype)initWithData:(NSString *)accessKey
               withSecretKey:(NSString*)secretKey{
    if (self = [super init]) {
        _accessKey = accessKey;
        _secretKey = secretKey;
    }
    return self;
}

-(NSString *) generateExternalUrl:(NSString *)method
                   expireDuration:(int32_t)expireDuration
                         hostName:hostname
                           bucket:bucket
                          keyPath:keyPath{
    
    NSMutableString *queryString = [NSMutableString new];
    
    //Get ClockSkew Fixed Date
    NSDate *currentDate = [[NSDate date] dateByAddingTimeInterval:-1 * _clockskew];
    
    [queryString appendFormat:@"%@=%@&",@"AWSAccessKeyId",_accessKey];

    //Expires, Provides the time period, in seconds, for which the generated presigned URL is valid.
    //For example, 86400 (24 hours). This value is an integer. The minimum value you can set is 1, and the maximum is 604800 (seven days).
    [queryString appendFormat:@"%@=%d&", @"Expires", expireDuration];
    
    NSString * tosign_string = [NSString stringWithFormat:@"%@\n\n\n%d\n/%@/%@",
                                method,
                                expireDuration,
                                bucket,
                                keyPath];
    
    const char *cKey  = [_secretKey cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [tosign_string cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    NSString *hash = [HMAC base64EncodedStringWithOptions:0];
    
    
    [queryString appendFormat:@"%@=%@", @"Signature", hash];
    
    return [NSString stringWithFormat:@"%@://%@.%@/%@?%@",@"https" ,bucket, hostname, keyPath, queryString];
}
@end
