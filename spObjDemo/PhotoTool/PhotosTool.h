//
//  PhotosTool.h
//  Photos使用
//
//  Created by 软件开发部2 on 2018/3/22.
//  Copyright © 2018年 软件开发部2. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
//定义一个返回数据的block
typedef void(^completion)(BOOL result, NSArray *datas);
@interface PhotosTool : NSObject<UIAlertViewDelegate,UIAlertViewDelegate,PHPhotoLibraryChangeObserver>

+(instancetype)sharedTool;
- (void)requestCollectionWithHandler:(completion)handler;
- (void)requestAssetsWithCollection:(PHAssetCollection *)collection andHandler:(completion)handler;
- (void)requestImgaeWithSize:(CGSize)size andAsset:(PHAsset *)asset andCompletionHandler:(void(^)(UIImage *result))handler;
- (void)requestImgaeWithSize:(CGSize)size andCropRect:(CGRect)rect andAsset:(PHAsset *)asset andCompletionHandler:(void(^)(UIImage *result))handler;
- (void)requestVideoWithAsset:(PHAsset *)asset andCompletionHandler:(void(^)(NSString *filePath))handler;
- (void)createLivePhotoWithVideoPath:(NSString *)videoPath andImagePath:(NSString *)imagePath;
- (void)requestLivePhotoWithAsset:(PHAsset *)asset andCompletion:(void(^)(PHLivePhoto *livephoto))handler;
- (void)requestDataForLivePhotoWithAsset:(PHAsset *)asset andCompletion:(void(^)(NSString *imagePath, NSString *videoPath))completion;
- (void)saveLivePhotoWithVedioURL:(NSURL *)videoUrl andImageURL:(NSURL *)imageUrl andCompletion:(void(^)(PHLivePhoto *livePhoto, BOOL success))completion;
- (void)saveImageWithImage:(UIImage *)image andCompletion:(void(^)(BOOL result, PHAsset *asset))completion;
- (void)saveImageWithImage:(UIImage *)image andCollection:(PHAssetCollection *)collection andCompletion:(void(^)(BOOL result, PHAsset *asset))completion;
- (void)createAssetsCollectionWithName:(NSString *)name;
@end
