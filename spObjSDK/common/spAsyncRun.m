//
//  spAsyncRun.m
//  spObjSDK
//
//  Created by YanBo on 2018/3/19.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "spAsyncRun.h"
#import <Foundation/Foundation.h>

void spAsyncRun(spRun run) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        run();
    });
}

void spAsyncRunInMain(spRun run) {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        run();
    });
}
