//
//  spDownloadDelegate.h
//  spDownloadManagerDemo
//
//  Created by tany on 16/6/24.
//  Copyright © 2016年 tany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "spDownloadModel.h"

// 下载代理
@protocol spDownloadDelegate <NSObject>

// 更新下载进度
- (void)downloadModel:(spDownloadModel *)downloadModel didUpdateProgress:(spDownloadProgress *)progress;

// 更新下载状态
- (void)downloadModel:(spDownloadModel *)downloadModel didChangeState:(spDownloadState)state filePath:(NSString *)filePath error:(NSError *)error;

@end
