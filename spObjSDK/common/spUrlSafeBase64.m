//
//  spUrlSafeBase64.m
//  spObjSDK
//
//  Created by YanBo on 2018/3/26.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spUrlSafeBase64.h"
#import "spGTMBase64.h"

@implementation spUrlSafeBase64

+ (NSString *)encodeString:(NSString *)sourceString {
    NSData *data = [NSData dataWithBytes:[sourceString UTF8String] length:[sourceString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    return [self encodeData:data];
}

+ (NSString *)encodeData:(NSData *)data {
    return [spGTMBase64 stringByWebSafeEncodingData:data padded:YES];
}

+ (NSData *)decodeString:(NSString *)data {
    return [spGTMBase64 webSafeDecodeString:data];
}

@end
