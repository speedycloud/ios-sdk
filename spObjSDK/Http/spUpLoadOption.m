//
//  spUploadOption.m
//  spObjSDK
//
//  Created by YanBo on 2018/3/16.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spUpLoadOption.h"

static NSString *mime(NSString *mimeType) {
    if (mimeType == nil || [mimeType isEqualToString:@""]) {
        return @"application/x-www-form-urlencoded";
    }
    return mimeType;
}

@implementation spUpLoadOption

+ (NSDictionary *)filteParam:(NSDictionary *)params {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    if (params == nil) {
        return ret;
    }
    
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        if (![obj isEqualToString:@""]) {
            ret[key] = obj;
        }
    }];
    
    return ret;
}

- (instancetype)initWithMime:(NSString *)mimeType
             progressHandler:(spUpProgressHandler)progress
                      params:(NSDictionary *)params
//                    checkCrc:(BOOL)check
          cancellationSignal:(spUpCancellationSignal)cancel {
    if (self = [super init]) {
        _mimeType = mime(mimeType);
        _progressHandler = progress != nil ? progress : ^(NSString *key, float percent) {
        };
        _params = [spUpLoadOption filteParam:params];
//        _checkCrc = check;
        _cancellationSignal = cancel != nil ? cancel : ^BOOL() {
            return NO;
        };
    }
    
    return self;
}

- (instancetype)initWithProgressHandler:(spUpProgressHandler)progress {
    return [self initWithMime:nil progressHandler:progress params:nil /*checkCrc:NO*/ cancellationSignal:nil];
}

+ (instancetype)defaultOptions {
    return [[spUpLoadOption alloc] initWithMime:nil progressHandler:nil params:nil /*checkCrc:NO*/ cancellationSignal:nil];
}


@end
