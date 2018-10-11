//
//  spConfigure.m
//  spObjSDK
//
//  Created by YanBo on 2018/3/14.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spConfigure.h"

const UInt32 upSpBlockSize = (5 * 1024 * 1024);

@implementation spConfigure

+ (instancetype)build:(spConfigureBuilderBlock)block {
    spConfigureBuilder *builder = [[spConfigureBuilder alloc] init];
    block(builder);
    return [[spConfigure alloc] initWithBuilder:builder];
}

- (instancetype)initWithBuilder:(spConfigureBuilder *)builder {
    if (self = [super init]) {
        
        _chunkSize = builder.chunkSize;
//        _putThreshold = builder.putThreshold;
        _retryMax = builder.retryMax;
//        _timeoutInterval = builder.timeoutInterval;
//
        _baseServer = builder.baseServer;
        _recorder = builder.recorder;
        _uploadBucket = builder.uploadBucket;
        _uploadKey = builder.uploaKey;
        _uploadAccessKey = builder.uploadAccessKey;
        _uploadSecretKey = builder.uploadSecretKey;
        _bResJsonType = builder.bResJsonType;
        _recorderKeyGen = builder.recorderKeyGen;
//
//        _proxy = builder.proxy;
//
//        _converter = builder.converter;
//
//        _disableATS = builder.disableATS;
//        if (_disableATS) {
//            _dns = initDns(builder);
//        } else {
//            _dns = nil;
//        }
//        _zone = builder.zone;
//
//        _useHttps = builder.useHttps;
    }
    return self;
}

@end

@implementation spConfigureBuilder

- (instancetype)init {
    if (self = [super init]) {
        _baseServer = @"http://oss-cn-shanghai.speedycloud.org";
        _uploadBucket = nil;
        _uploaKey = nil;
        _uploadAccessKey = nil;
        _uploadSecretKey = nil;
        _bResJsonType = TRUE;
        //        _zone = [[QNAutoZone alloc] initWithDns:nil];
                _chunkSize = upSpBlockSize;
        //        _putThreshold = 4 * 1024 * 1024;
                _retryMax = 3;
        //        _timeoutInterval = 60;
        //
                _recorder = nil;
                _recorderKeyGen = nil;
        //
        //        _proxy = nil;
        //        _converter = nil;
        //
        //        if (hasAts() && !allowsArbitraryLoads()) {
        //            _disableATS = NO;
        //        } else {
        //            _disableATS = YES;
        //        }
        //
        //        _useHttps = YES;
    }
    return self;
}

@end
