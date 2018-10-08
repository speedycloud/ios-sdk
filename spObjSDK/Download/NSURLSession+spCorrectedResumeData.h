//
//  NSURLSession+spCorrectedResumeData.h
//  TYDownloadManagerDemo
//
//  Created by tanyang on 2016/10/7.
//  Copyright © 2016年 tany. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (spCorrectedResumeData)

- (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData;

@end
