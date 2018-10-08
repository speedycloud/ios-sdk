//
//  spResumeUpload.h
//  spObjSDK
//  用于断点续传
//  Created by YanBo on 2018/3/20.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spFileDelegate.h"
#import "spHttpDelegate.h"
//#import "QNUpToken.h"
#import "spRecorderDelegate.h"
#import "spObjUpLoadManager.h"
#import <Foundation/Foundation.h>

@interface spResumeUpload : NSObject

- (instancetype)initWithFile:(id<spFileDelegate>)file
                  withBucket:(NSString *)bucket
                     withKey:(NSString *)key
//                   withToken:(QNUpToken *)token
       withCompletionHandler:(spUpCompletionHandler)block
                  withOption:(spUpLoadOption *)option
                withRecorder:(id<spRecorderDelegate>)recorder
             withRecorderKey:(NSString *)recorderKey
             withHttpManager:(id<spHttpDelegate>)http
           withConfiguration:(spConfigure *)config;

- (void)run;

@end
