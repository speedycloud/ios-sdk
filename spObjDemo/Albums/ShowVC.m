//
//  ShowVC.m
//  Photos使用
//
//  Created by 软件开发部2 on 2018/3/22.
//  Copyright © 2018年 软件开发部2. All rights reserved.
//

#import "ShowVC.h"
#import "PhotosTool.h"
#import <PhotosUI/PhotosUI.h>
#import "SVProgressHUD.h"
#import "ViewController.h"

#define SPhotoUrlPath   \
[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"PhotoURL"]

@interface ShowVC ()<PHLivePhotoViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *poster;
@property (nonatomic,strong) PHLivePhotoView *liveView;
@property (nonatomic,strong) NSString * uploadVideoPath;
@property (nonatomic,strong) NSString * uploadPhotoPath;

@end

@implementation ShowVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadImage];
}
- (void)setupUI {
    _liveView = [[PHLivePhotoView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:_liveView];
    _liveView.delegate = self;
    _liveView.hidden = YES;
}
- (void)loadImage {
    if (_asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
        _liveView.hidden = NO;
        PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc] init];
        option.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestLivePhotoForAsset:_asset targetSize:CGSizeMake(_asset.pixelWidth, _asset.pixelHeight) contentMode:PHImageContentModeAspectFit options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
            _liveView.livePhoto = livePhoto;
            [_liveView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        }];
       
    }else {
        [[PhotosTool sharedTool] requestImgaeWithSize:CGSizeMake(_asset.pixelWidth, _asset.pixelHeight) andAsset:_asset andCompletionHandler:^(UIImage *result) {
            _poster.image = result;
            [SVProgressHUD showInfoWithStatus:@"滑动图片开始上传"];
        }];
    }
   
   
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
//    _uploadVideoPath = [NSString stringWithFormat:@"%@/%@",SVideoUrlPath,@"upvideo.mp4"];
    _uploadPhotoPath = [NSString stringWithFormat:@"%@/%@",SPhotoUrlPath,@"upphoto.jpeg"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:SPhotoUrlPath]) {
        [fileManager createDirectoryAtPath:SPhotoUrlPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    BOOL res= [fileManager removeItemAtPath:_uploadPhotoPath error:nil];
    if (res) {
        NSLog(@"文件删除成功");
    }else
        NSLog(@"文件删除失败");
    NSLog(@"文件是否存在: %@",[fileManager isExecutableFileAtPath:_uploadPhotoPath]?@"YES":@"NO");
    
    [UIImageJPEGRepresentation(_poster.image, 1.0)writeToFile: _uploadPhotoPath atomically:YES];
    
    for(UIViewController *controller in self.navigationController.viewControllers) {
            if([controller isKindOfClass:[ViewController class]]) {
                ViewController * upViewControl = (ViewController *)controller;
                upViewControl.uploadFilePath = _uploadPhotoPath;
                [self.navigationController popToViewController:controller animated:YES];
             }
    }
}

#pragma mark - PHLivePhotoViewDelegate
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    
}
@end
