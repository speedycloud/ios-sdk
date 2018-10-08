//
//  spHeaderSignOrToken.m
//  spObjSDK
//
//  Created by YanBo on 2018/3/20.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spHeaderSignOrToken.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>

@implementation spHeaderSignOrToken

- (instancetype)initWithData:(NSString *)accessKey
               withSecretKey:(NSString*)secretKey{
    if (self = [super init]) {
        _accessKey = accessKey;
        _secretKey = secretKey;
    }
    return self;
}

-(NSDictionary *) generateHeaders:(NSString *)method params:(NSDictionary *)params isJson:(BOOL)isJson{
    NSString *dateStr = [self dateFormat];
    NSString *sign = [self genSig:method params:params];
    NSLog(@"sign is %@", sign);
    
    NSString *authorization = [NSString stringWithFormat:@"AWS %@:%@", _accessKey, sign];
    NSMutableDictionary *header_data = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                        dateStr, @"Date",
                                        authorization, @"Authorization",
                                        nil];
    
    NSString *acl = params[@"x-amz-acl"];
    if(acl != nil) {
        header_data[@"x-amz-acl"] = acl;
    }
    
    NSString *content_length = params[@"content_length"];
    if(content_length != nil) {
        header_data[@"Content-Length"] = content_length;
    }
    
    
    NSString *content_type = params[@"content_type"];
    if(content_type != nil) {
        header_data[@"Content-Type"] = content_type;
    }
    
    if(isJson) {
        header_data[@"Accept-Encoding"] = @"";
    }
    
    for (NSString *key in header_data) {
        NSLog(@"key:%@ value:%@",key,header_data[key]);
    }
    
    return header_data;
}

-(NSString *) dateFormat {
    NSTimeInterval interval = 8 * 3600;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-interval];
    
    NSDateFormatter *forMatter = [[NSDateFormatter alloc] init];
    forMatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    [forMatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss"];
    
    NSString *dateStr = [forMatter stringFromDate:date];
    NSString *result = [NSString stringWithFormat:@"%@ GMT", dateStr];
    
    return result;
}

-(NSString *) genSigStr:(NSDictionary *)params {
    NSString *result = @"";
    
    NSString *http_method = params[@"http_method"];
    if(http_method != nil) {
        result = [NSString stringWithFormat:@"%@", http_method];
    }
    
    NSString *content_md5 = params[@"content_md5"];
    if(content_md5 == nil) {
        content_md5 = @"";
    }
    result = [NSString stringWithFormat:@"%@\n%@", result, content_md5];
    
    NSString *content_type = params[@"content_type"];
    if(content_type == nil) {
        content_type = @"";
    }
    result = [NSString stringWithFormat:@"%@\n%@", result, content_type];
    
    
    result = [NSString stringWithFormat:@"%@\n%@", result, [self dateFormat]];
    
    NSString *canonicalized_amz_headers = params[@"canonicalized_amz_headers"];
    if(canonicalized_amz_headers != nil) {
        result = [NSString stringWithFormat:@"%@\n%@", result, canonicalized_amz_headers];
    }
    
    result = [NSString stringWithFormat:@"%@\n/%@", result, params[@"url"]];
//    if(self.SHOW_DEBUG) {
//        NSLog(@"%@", result);
//    }
    return result;
}

-(NSString *) genSig:(NSString *)method params:(NSMutableDictionary *)params{
    NSString *canonicalized_amz_headers = @"";
    
    NSString *amz = params[@"x-amz-acl"];
    if(amz != nil) {
        canonicalized_amz_headers = [NSString stringWithFormat:@"x-amz-acl:%@", amz];
        params[@"canonicalized_amz_headers"] = canonicalized_amz_headers;
    }
    
    NSString *sigStr = [self genSigStr:params];
    NSString *result = [self hmacsha1:sigStr];
    
    return result;
}


-(NSString *) hmacsha1:(NSString *)str {
    const char *cKey  = [_secretKey cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [str cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    NSString *hash = [HMAC base64EncodedStringWithOptions:0];
    
    return hash;
}

@end
