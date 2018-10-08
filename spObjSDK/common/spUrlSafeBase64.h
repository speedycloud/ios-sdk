//
//  spUrlSafeBase64.h
//  spObjSDK
//
//  Created by YanBo on 2018/3/26.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
*    url safe base64 编码类, 对/ 做了处理
*/
@interface spUrlSafeBase64 : NSObject

/**
 *    字符串编码
 *
 *    @param source 字符串
 *
 *    @return base64 字符串
 */
+ (NSString *)encodeString:(NSString *)source;

/**
 *    二进制数据编码
 *
 *    @param source 二进制数据
 *
 *    @return base64字符串
 */
+ (NSString *)encodeData:(NSData *)source;

/**
 *    字符串解码
 *
 *    @param base64 字符串
 *
 *    @return 数据
 */
+ (NSData *)decodeString:(NSString *)data;

@end

