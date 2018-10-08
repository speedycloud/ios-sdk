//
//  spFile.h
//  spObjSDK
//
//  Created by YanBo on 2018/3/20.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spFileDelegate.h"
#import <Foundation/Foundation.h>

@interface spFile : NSObject <spFileDelegate>
/**
 *    打开指定文件
 *
 *    @param path      文件路径
 *    @param error     输出的错误信息
 *
 *    @return 实例
 */
- (instancetype)init:(NSString *)path
               error:(NSError *__autoreleasing *)error;

@end
