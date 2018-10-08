//
//  spFormUpload.h
//  spObjSDK
//  所有表单指令
//  Created by YanBo on 2018/3/19.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spObjUpLoadManager.h"
#import "spUpLoadOption.h"
#import "spHttpDelegate.h"
#import <Foundation/Foundation.h>

@interface spFormUpload : NSObject

- (instancetype)initWithData:(NSData *)data
                     withUrl:(NSString *)url
                    withPath:(NSString *)path
                     withKey:(NSString *)key
       withCompletionHandler:(spUpCompletionHandler)block
                  withOption:(spUpLoadOption *)option
             withHttpManager:(id<spHttpDelegate>)http
           withConfiguration:(spConfigure *)config;
- (void)post;

- (void)put;

- (void)get;

- (void)del;

@end
