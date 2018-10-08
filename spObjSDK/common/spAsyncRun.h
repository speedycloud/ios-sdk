//
//  spAsyncRun.h
//  spObjSDK
//
//  Created by YanBo on 2018/3/19.
//  Copyright © 2018年 YanBo. All rights reserved.
//

typedef void (^spRun)(void);

void spAsyncRun(spRun run);

void spAsyncRunInMain(spRun run);
