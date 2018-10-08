//
//  SPResponseInfo.m
//  spObjSDK
//
//  Created by YanBo on 2018/3/14.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spResponseInfo.h"

const int eSpZeroDataSize = -6;
const int eSpInvalidToken = -5;
const int eSpFileError = -4;
const int eSpInvalidArgument = -3;
const int eSpRequestCancelled = -2;
const int eSpNetworkError = -1;

const NSString * strSpBucketAclPrivate = @"private";
const NSString * strSpBucketAclPublicR = @"public-read";
const NSString * strSpBucketAclPrivatRW = @"public-read-write";

const NSString * strSpBucketVersionEnabled = @"Enabled";
const NSString * strSpBucketVersionSuspended = @"Suspended";

static NSString *domain = @"speedy.com";

@implementation spResponseInfo

+ (instancetype)cancel {
    return [[spResponseInfo alloc] initWithCancelled];
}

- (instancetype)init:(int)status
           withReqId:(NSString *)reqId
            withETAG:(NSString *)etag
            withXLog:(NSString *)xlog
            withXVia:(NSString *)xvia
            withHost:(NSString *)host
              withIp:(NSString *)ip
        withDuration:(double)duration
            withBody:(NSData *)body {
    if (self = [super init]) {
        _statusCode = status;
        _reqId = reqId;
        _eTag = etag;
//        _xlog = xlog;
//        _xvia = xvia;
//        _host = host;
//        _duration = duration;
//        _serverIp = ip;
//        _id = [QNUserAgent sharedInstance].id;
//        _timeStamp = [[NSDate date] timeIntervalSince1970];
        if (status != 200) {
            if (body == nil) {
                _error = [[NSError alloc] initWithDomain:domain code:_statusCode userInfo:nil];
            } else {
                NSError *tmp;
                NSDictionary *uInfo = [NSJSONSerialization JSONObjectWithData:body options:NSJSONReadingMutableLeaves error:&tmp];
                if (tmp != nil) {
                    // 出现错误时，如果信息是非UTF8编码会失败，返回nil
                    NSString *str = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
                    if (str == nil) {
                        str = @"";
                    }
                    uInfo = @{ @"error" : str };
                }
                _error = [[NSError alloc] initWithDomain:domain code:_statusCode userInfo:uInfo];
            }
        }
//        } else if (body == nil || body.length == 0) {
//            NSDictionary *uInfo = @{ @"error" : @"no response json" };
//            _error = [[NSError alloc] initWithDomain:domain code:_statusCode userInfo:uInfo];
//        }
    }
    return self;
}

+ (instancetype)responseInfoWithNetError:(NSError *)error host:(NSString *)host duration:(double)duration {
    int code = eSpNetworkError;
    if (error != nil) {
        code = (int)error.code;
    }
    return [[spResponseInfo alloc] initWithStatus:code error:error host:host duration:duration];
}

- (instancetype)initWithCancelled {
    return [self initWithStatus:eSpRequestCancelled errorDescription:@"cancelled by user"];
}

- (instancetype)initWithStatus:(int)status
                         error:(NSError *)error {
    return [self initWithStatus:status error:error host:nil duration:0];
}

- (instancetype)initWithStatus:(int)status
                         error:(NSError *)error
                          host:(NSString *)host
                      duration:(double)duration {
    if (self = [super init]) {
        _statusCode = status;
        _error = error;
//        _host = host;
//        _duration = duration;
//        _id = [QNUserAgent sharedInstance].id;
//        _timeStamp = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

- (instancetype)initWithStatus:(int)status
              errorDescription:(NSString *)text {
    NSError * error = nil;
//    NSError *error = [[NSError alloc] initWithDomain:domain code:status userInfo:@{ @"error" : text }];
    return [self initWithStatus:status error:error];
}

- (BOOL)isOK {
    return _statusCode == 200 && _error == nil;// && _reqId != nil;
}

- (BOOL)couldRetry {
    return (_statusCode >= 500 && _statusCode < 600 && _statusCode != 579) || _statusCode == eSpNetworkError || _statusCode == 996 || _statusCode == 406 || (_statusCode == 200 && _error != nil) || _statusCode < -1000 || self.isNotSpeedy;
}

- (BOOL)isNotSpeedy {
    return (_statusCode >= 200 && _statusCode < 500) && _reqId == nil;
}

@end
