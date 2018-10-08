//
//  spFileRecorder.m
//  spObjSDK
//
//  Created by YanBo on 2018/3/26.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spFileRecorder.h"
#import "spUrlSafeBase64.h"
#import <Foundation/Foundation.h>

@interface spFileRecorder ()

@property (copy, readonly) NSString *directory;
@property BOOL encode;

@end

@implementation spFileRecorder

- (NSString *)pathOfKey:(NSString *)key {
    return [spFileRecorder pathJoin:key path:_directory];
}

+ (NSString *)pathJoin:(NSString *)key
                  path:(NSString *)path {
    return [[NSString alloc] initWithFormat:@"%@/%@", path, key];
}

+ (instancetype)fileRecorderWithFolder:(NSString *)directory
                                 error:(NSError *__autoreleasing *)perror {
    return [spFileRecorder fileRecorderWithFolder:directory encodeKey:false error:perror];
}

+ (instancetype)fileRecorderWithFolder:(NSString *)directory
                             encodeKey:(BOOL)encode
                                 error:(NSError *__autoreleasing *)perror {
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil) {
        if (perror) {
            *perror = error;
        }
        return nil;
    }
    
    return [[spFileRecorder alloc] initWithFolder:directory encodeKey:encode];
}

- (instancetype)initWithFolder:(NSString *)directory encodeKey:(BOOL)encode {
    if (self = [super init]) {
        _directory = directory;
        _encode = encode;
    }
    return self;
}

- (NSError *)set:(NSString *)key
            data:(NSData *)value {
    NSError *error;
    if (_encode) {
        key = [spUrlSafeBase64 encodeString:key];
    }
    [value writeToFile:[self pathOfKey:key] options:NSDataWritingAtomic error:&error];
    return error;
}

- (NSData *)get:(NSString *)key {
    if (_encode) {
        key = [spUrlSafeBase64 encodeString:key];
    }
    return [NSData dataWithContentsOfFile:[self pathOfKey:key]];
}

- (NSError *)del:(NSString *)key {
    NSError *error;
    if (_encode) {
        key = [spUrlSafeBase64 encodeString:key];
    }
    [[NSFileManager defaultManager] removeItemAtPath:[self pathOfKey:key] error:&error];
    return error;
}

+ (void)removeKey:(NSString *)key
        directory:(NSString *)dir
        encodeKey:(BOOL)encode {
    if (encode) {
        key = [spUrlSafeBase64 encodeString:key];
    }
    NSError *error;
    NSString *path = [spFileRecorder pathJoin:key path:dir];
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (error) {
        NSLog(@"%s,%@", __func__, error);
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, dir: %@>", NSStringFromClass([self class]), self, _directory];
}

@end

