//
//  PhotosTool.m
//  Photos使用
//
//  Created by 软件开发部2 on 2018/3/22.
//  Copyright © 2018年 软件开发部2. All rights reserved.
//

#import "PhotosTool.h"

static PHPhotoLibrary *library = nil;
static PhotosTool *sharedTool = nil;

@implementation PhotosTool
+ (instancetype)sharedTool {
    static dispatch_once_t token;
    _dispatch_once(&token, ^{
        sharedTool = [[PhotosTool alloc] init];
        library = [PHPhotoLibrary sharedPhotoLibrary];
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:sharedTool];
    });
    return sharedTool;
}

//监测一下是否授权(没授权不能获取到数据)
- (BOOL)checkAuthorization {
    BOOL authorization = NO;
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {//已经授权
        authorization = YES;
    }
    return authorization;
}

//获取相册
- (void)requestCollectionWithHandler:(completion)handler {
    __block completion operation = handler;
    if ([self checkAuthorization]) {//授权成功
        __block NSMutableArray *arr1 = [NSMutableArray new];
        PHFetchResult *result1 = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumTimelapses options:nil];
        [result1 enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[PHAssetCollection class]]) {
                [arr1 addObject:(PHAssetCollection *)obj];
            }
        }];
        
         __block NSMutableArray *arr2 = [NSMutableArray new];
        PHFetchResult *result2 = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        
        [result2 enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[PHAssetCollection class]]) {
                [arr2 addObject:(PHAssetCollection *)obj];
            }
        }];
        [arr1 addObjectsFromArray:arr2];
        if (operation) {
            dispatch_async(dispatch_get_main_queue(), ^{
                operation(YES, arr1);
                operation = nil;
            });
        }
        
    }else {//授权失败
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                [self requestCollectionWithHandler:operation];
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请前往设置为应用打开照片访问权限" delegate:self cancelButtonTitle:@"设置" otherButtonTitles:@"取消", nil];
                    [alert show];
                });
               
            }
        }];
    }
    
}

//请求asset(对应图片,视频,livePhoto)资源
- (void)requestAssetsWithCollection:(PHAssetCollection *)collection andHandler:(completion)handler {
    __block completion operation = handler;
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.includeHiddenAssets = YES;
    __block NSMutableArray *arr = [NSMutableArray new];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[PHAsset class]]) {
            [arr addObject:(PHAsset *)obj];
        }
    }];
    if (operation) {
        dispatch_async(dispatch_get_main_queue(), ^{
            operation(YES, arr);
            operation = nil;
        });
    }
}

- (void)requestImgaeWithSize:(CGSize)size andAsset:(PHAsset *)asset andCompletionHandler:(void (^)(UIImage *))handler {
    __block void (^ operation)(UIImage *) = handler;
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    options.normalizedCropRect = CGRectMake(0, 0, 1, 1);
    [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (operation) {
            operation(result);
            operation = nil;
        }
    }];
}
- (void)requestImgaeWithSize:(CGSize)size andCropRect:(CGRect)rect andAsset:(PHAsset *)asset andCompletionHandler:(void (^)(UIImage *))handler {
    __block void (^ operation)(UIImage *) = handler;
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (operation) {
                operation(result);
                operation = nil;
            }
        });
    }];
}
- (void)requestVideoWithAsset:(PHAsset *)asset andCompletionHandler:(void(^)(NSString *filePath))handler{
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        PHAssetResource *one = nil;
        NSArray *arr = [PHAssetResource assetResourcesForAsset:asset];
        for (PHAssetResource *resource in arr) {
            if (resource.type == PHAssetResourceTypeVideo) {
                break;
            }
        }
        PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
        options.networkAccessAllowed = YES;//有可能资源得从icloud下载
        options.progressHandler = ^(double progress) {//监测进度
            
        };
        NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:one.originalFilename];
        [[PHAssetResourceManager defaultManager] writeDataForAssetResource:one toFile:[NSURL URLWithString:filePath] options:options completionHandler:^(NSError * _Nullable error) {
            if (error == nil) {
                NSLog(@"写入文件成功----");
            }
        }];
    }
}

- (void)writeDataWithFilePath:(NSString *)filePath {
    NSString *outPath = @"/Users/rjkfb2/Desktop/temp.mov";
    NSString *readPath = filePath;
    if ([readPath hasPrefix:@"file://"]) {
        readPath = [readPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    }
    NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:readPath];
    NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingAtPath:outPath];
    NSData *data = nil;
    while (1) {
        data = [readHandle readDataOfLength:1024];
        if (data != nil && data.length > 0) {
            [writeHandle writeData:data];
        }else {
            break;
        }
    }
    [readHandle closeFile];
    [writeHandle closeFile];
}
- (void)createLivePhotoWithVideoPath:(NSString *)videoPath andImagePath:(NSString *)imagePath {
    [library performChanges:
     ^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:[NSURL fileURLWithPath:imagePath] options:nil];
        
        [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:[NSURL fileURLWithPath:videoPath] options:nil];
        
    }
    completionHandler:
     ^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"保存成功----");
        }
         
    }];
}

- (void)requestLivePhotoWithAsset:(PHAsset *)asset andCompletion:(void (^)(PHLivePhoto *))handler {
    if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {//判断为LivePhoto
        NSArray *arr = [PHAssetResource assetResourcesForAsset:asset];
        NSLog(@"--------%@",arr);
    }
}
- (void)requestDataForLivePhotoWithAsset:(PHAsset *)asset andCompletion:(void (^)(NSString *, NSString *))completion {
    __block void (^handler)(NSString *, NSString *) = completion;
    NSString *imagePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *videoPath = imagePath;
    PHAssetResource *imageResource = nil;
    PHAssetResource *videoResource = nil;
    NSArray *resources = [PHAssetResource assetResourcesForAsset:asset];
    for (PHAssetResource *resource in resources) {
        if (resource.type == PHAssetResourceTypePairedVideo) {//LivePhoto
            videoResource = resource;
        }else if (resource.type == PHAssetResourceTypePhoto) {//image
            imageResource = resource;
        }
    }
    imagePath = [imagePath stringByAppendingPathComponent:@"one.jpg"];
    videoPath = [videoPath stringByAppendingPathComponent:@"one.mov"];
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [[PHAssetResourceManager defaultManager] writeDataForAssetResource:imageResource toFile:[NSURL fileURLWithPath:imagePath] options:options completionHandler:^(NSError * _Nullable error) {
        if (error == nil) {
            PHAssetResourceRequestOptions *options1 = [[PHAssetResourceRequestOptions alloc] init];
            options1.networkAccessAllowed = YES;
            [[PHAssetResourceManager defaultManager] writeDataForAssetResource:videoResource toFile:[NSURL fileURLWithPath:videoPath] options:options1 completionHandler:^(NSError * _Nullable error) {
                if (error == nil) {
                    handler(imagePath,videoPath);
                }else {
                    handler(nil,nil);
                }
            }];
        }else {
             handler(nil,nil);
        }
    }];
}
- (void)saveLivePhotoWithVedioURL:(NSURL *)videoUrl andImageURL:(NSURL *)imageUrl andCompletion:(void (^)(PHLivePhoto *, BOOL))completion{
    __block void (^handler)(PHLivePhoto *, BOOL) = completion;
    __block NSString *localIdentifier = @"";
    [library performChanges:^{
        PHAssetCreationRequest *request = [[PHAssetCreationRequest alloc] init];
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:imageUrl options:nil];
        [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:videoUrl options:nil];
        //获取对应的标识符,用于获取资源
        localIdentifier = [request placeholderForCreatedAsset].localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {//保存成功之后,返回PHLivePhoto对象
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
        __block PHAsset *asset = nil;
        [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:PHAsset.class]) {
                asset = (PHAsset *)obj;
                if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                    [[PHImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (livePhoto) {
                                handler(livePhoto, YES);
                                handler = nil;
                            }else {
                                handler(nil,NO);
                            }
                        });
                    }];
                }
            }
        }];
    } ];
}
//保存到系统相册
- (void)saveImageWithImage:(UIImage *)image andCompletion:(void (^)(BOOL, PHAsset *))completion {
    __block void(^handler)(BOOL, PHAsset *) = completion;
    __block NSString *identifier = @"";
    [library performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        identifier =  [request placeholderForCreatedAsset].localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        __block PHAsset *asset = nil;
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
        [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:PHAsset.class]) {
                asset = (PHAsset *)obj;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(YES , asset);
                        handler = nil;
                    }
                });
                return;
            }
            
        }];
    }];
}
//保存到指定相册
-  (void)saveImageWithImage:(UIImage *)image andCollection:(PHAssetCollection *)collection andCompletion:(void (^)(BOOL, PHAsset *))completion {
    __block void(^handler)(BOOL, PHAsset *) = completion;
    __block NSString *identifier = @"";
    [library performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        PHAssetCollectionChangeRequest *collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        [collectionRequest addAssets:@[request.placeholderForCreatedAsset]];
        identifier =  [request placeholderForCreatedAsset].localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        __block PHAsset *asset = nil;
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
        [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:PHAsset.class]) {
                asset = (PHAsset *)obj;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(YES , asset);
                        handler = nil;
                    }
                });
                return;
            }
            
        }];
    }];
}
//新建相册
- (void)createAssetsCollectionWithName:(NSString *)name {
    [library performChanges:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        
    }];
}
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:nil completionHandler:nil];
    }
}
@end
