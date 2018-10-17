//
//  ViewController.m
//  spObjDemo
//
//  Created by YanBo on 2018/3/11.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import "ViewController.h"
#import "spObjSDK.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "AlbumsVC.h"

#import <MediaPlayer/MediaPlayer.h>

//图片存储路径
#define KVideoUrlPath   \
[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"PhotoURL"]
#define kHeight [[UIScreen mainScreen] bounds].size.height
#define kWidth  [[UIScreen mainScreen] bounds].size.width

#define ACCESSKEY @"D45CFEE53110F9EC03D559EF8E2372C6"
#define SECRETKEY @"26e5a70bdb0a5eb8100eae1fbebefedfb2d30530e98b3c144c07627f2cc20a32"

@interface ViewController ()<spDownloadDelegate>

@property (nonatomic,strong) spDownloadModel *downloadModel;
@property spDownloadSessionManager *downManager;

@end

@implementation ViewController


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if(self.uploadFilePath.length > 0){
        NSLog(@"选择图片后返回的要上传 url:%@",self.uploadFilePath);
        [self prePush];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIColor *backColor = [UIColor colorWithRed:0.1f green:0.9f blue:0.1f alpha:1.0f];
    UIColor *textColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.9f alpha:1.0f];
    
    // Label 桶名:
    UILabel* bucketNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(20 ,50 , 80, 40)];
    [bucketNameLabel setText:@"桶名:"];
    [bucketNameLabel setTextAlignment:NSTextAlignmentCenter];
    [bucketNameLabel setTextColor:textColor];
    [bucketNameLabel setBackgroundColor:backColor];
    [self.view addSubview:bucketNameLabel];
    
    // Label 对象名:
    UILabel* objNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(20 ,50 + 40 + 3 , 80, 40)];
    [objNameLabel setText:@"对象名:"];
    [objNameLabel setTextAlignment:NSTextAlignmentCenter];
    [objNameLabel setTextColor:textColor];
    [objNameLabel setBackgroundColor:backColor];
    [self.view addSubview:objNameLabel];
    
    // UILabel 对象名显示
    _objShow = [[UILabel alloc]initWithFrame:CGRectMake(20,50 + 12 * (40 + 3) , kWidth - 40, 40)];
    [_objShow setText:@"对象名:"];
    [_objShow setTextAlignment:NSTextAlignmentLeft];
    [_objShow setTextColor:textColor];
    [_objShow setBackgroundColor:[UIColor yellowColor]];
    [self.view addSubview:_objShow];
    
    // UILabel 错误显示
    _errorShow = [[UILabel alloc]initWithFrame:CGRectMake(20,50 + 13 * (40 + 3) , kWidth - 100, 40)];
    [_errorShow setText:@"返回信息:"];
    [_errorShow setTextAlignment:NSTextAlignmentLeft];
    [_errorShow setTextColor:textColor];
    [_errorShow setBackgroundColor:[UIColor yellowColor]];
    [self.view addSubview:_errorShow];
    
    // UILabel 详细..
    UIButton * detailShow = [[UIButton alloc]initWithFrame:CGRectMake(20 + kWidth - 98,50 + 13 * (40 + 3) , 58, 40)];
    [detailShow setTitle:@"详细..." forState:UIControlStateNormal];
    [detailShow setTitleColor:textColor forState:UIControlStateNormal];
    [detailShow setBackgroundColor:[UIColor yellowColor]];
    [detailShow addTarget:self action:@selector(showDetailInfoClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:detailShow];
    
//    _bucketField = [[UITextField alloc] initWithFrame:CGRectMake(20 + 82 ,50 + 40 + 3 , (kWidth - 20 - 80), 40)];
//    _bucketField.font = [UIFont fontWithName:@"Arial" size:20.0f];
//    [_bucketField setText:@"iosbucketsh"];
//    [self.view addSubview:_bucketField];
//
//    _objField = [[UITextField alloc] initWithFrame:CGRectMake(20 + 82 ,50 + 2 * (40 + 3) , (kWidth - 20 - 80), 40)];
//    _objField.font = [UIFont fontWithName:@"Arial" size:20.0f];
//    [_objField setText:@"iosobjtest.jpeg"];
//    [self.view addSubview:_objField];
//    [_bucketField becomeFirstResponder];
    
    _appfileName = @"newupload.jpeg";// 保存沙盒中的文件名称
    
    _bPauseStatus = NO;
    NSError *error = nil;
    
    _downManager = [spDownLoadDataManager manager:ACCESSKEY secretKey:SECRETKEY];
    _downManager.delegate = self;
    
    __block spFileRecorder *file = [spFileRecorder fileRecorderWithFolder:[NSTemporaryDirectory() stringByAppendingString:@"xundayun"] error:&error];
    NSLog(@"recorder error %@", error);
    spConfigure *config = [spConfigure build:^(spConfigureBuilder *builder) {
        builder.uploadAccessKey = ACCESSKEY;
        builder.uploadSecretKey = SECRETKEY;
        builder.recorder = file;
    }];
     __weak typeof(self) weakSelf = self;
    _opt = [[spUpLoadOption alloc] initWithMime:@"image/jpeg" progressHandler:^(NSString *key, float percent) {
        NSLog(@"key:%@ percent:%f%%",key,percent*100.0);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showProcessText:[NSString stringWithFormat:@"进度:%f%%",percent * 100.0f]];
            [weakSelf showObjNameText:[NSString stringWithFormat:@"对象名:%@",key ]];
        });
    }
                                                        params:nil
                                            cancellationSignal:^BOOL() {
                                                return _bPauseStatus;
                                            }];
    
    _upManager = [[spObjUpLoadManager alloc] initWithConfigure:config];
    NSLog(@"版本号:%@",[_upManager getSDKVersion]);
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidLayoutSubviews{
    NSLog(@"viewDidLayoutSubviews");
    NSString *path = [[NSBundle mainBundle]pathForResource:@"iosBack"ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    self.view.layer.contents = (id)image.CGImage;
    
    UIColor *backColor = [UIColor colorWithRed:0.1f green:0.9f blue:0.1f alpha:1.0f];
    UIColor *textColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.9f alpha:1.0f];
    
    // Edit 桶名
    _bucketField = [[UITextField alloc] initWithFrame:CGRectMake(20 + 80 + 3 ,50 , kWidth - 40 - 80 -3, 40)];
    [_bucketField setPlaceholder:@"请输入桶名"];
    [_bucketField setTextColor:textColor];
    [_bucketField setBackgroundColor:[UIColor whiteColor]];
    _bucketField.font = [UIFont fontWithName:@"Arial" size:20.0f];
    [_bucketField setText:@"iosbucketsh"];
    [self.view addSubview:_bucketField];
    
    // Edit 对象名
    _objField = [[UITextField alloc] initWithFrame:CGRectMake(20 + 80 + 3 ,50 + 40 + 3, kWidth - 40 - 80 -3, 40)];
    [_objField setFrame:CGRectMake(20 + 80 + 3 ,50 + 40 + 3, kWidth - 40 - 80 -3, 40)];
    [_objField setPlaceholder:@"请输入对象名"];
    [_objField setTextColor:textColor];
    [_objField setBackgroundColor:[UIColor whiteColor]];
    _objField.font = [UIFont fontWithName:@"Arial" size:20.0f];
    [_objField setText:@"iosobjtest.jpeg"];
    [self.view addSubview:_objField];
    
    // Button 创建桶
    _createBucketButton = [[UIButton alloc] initWithFrame:CGRectMake(20 ,50 + 2*(40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_createBucketButton setTitle:@"创建桶" forState:UIControlStateNormal];
    [_createBucketButton setTitleColor:textColor forState:UIControlStateNormal];
    [_createBucketButton setBackgroundColor:backColor];
    [_createBucketButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_createBucketButton];
    
    // Button 查询桶权限
    _queryBucketButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 2*(40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_queryBucketButton setTitle:@"查询桶权限" forState:UIControlStateNormal];
    [_queryBucketButton setTitleColor:textColor forState:UIControlStateNormal];
    [_queryBucketButton setBackgroundColor:backColor];
    [_queryBucketButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_queryBucketButton];
    
    // Button 上传图片
    _pushButton = [[UIButton alloc] initWithFrame:CGRectMake(20 ,50 + 3*(40 + 3) , (kWidth - 40)/4, 40)];
    [_pushButton setTitle:@"上传图片" forState:UIControlStateNormal];
    [_pushButton setTitleColor:textColor forState:UIControlStateNormal];
    [_pushButton setBackgroundColor:backColor];
    [_pushButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_pushButton];
    
    // Button 拍摄上传
    _takePhotoPushButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/4 + 1,50 + 3*(40 + 3) , (kWidth - 40)/4, 40)];
    [_takePhotoPushButton setTitle:@"拍摄上传" forState:UIControlStateNormal];
    [_takePhotoPushButton setTitleColor:textColor forState:UIControlStateNormal];
    [_takePhotoPushButton setBackgroundColor:backColor];
    [_takePhotoPushButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_takePhotoPushButton];
    
    // Button 暂停上传
    _cancelPushButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 3*(40 + 3) , (kWidth - 40)/4 - 2, 40)];
    [_cancelPushButton setTitle:@"暂停上传" forState:UIControlStateNormal];
    [_cancelPushButton setTitleColor:textColor forState:UIControlStateNormal];
    [_cancelPushButton setBackgroundColor:backColor];
    [_cancelPushButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cancelPushButton];
    
    // Button 继续上传
    _continuePushButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 + (kWidth - 40)/4 + 2 ,50 + 3*(40 + 3) , (kWidth - 40)/4 - 2, 40)];
    [_continuePushButton setTitle:@"继续上传" forState:UIControlStateNormal];
    [_continuePushButton setTitleColor:textColor forState:UIControlStateNormal];
    [_continuePushButton setBackgroundColor:backColor];
    [_continuePushButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_continuePushButton];
    
    // Button 删除对象
    _deleteObjButton = [[UIButton alloc] initWithFrame:CGRectMake(20 ,50 + 4 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_deleteObjButton setTitle:@"删除对象" forState:UIControlStateNormal];
    [_deleteObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [_deleteObjButton setBackgroundColor:backColor];
    [_deleteObjButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_deleteObjButton];
    
    // Button 查询对象权限
    _queryObjButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 4 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_queryObjButton setTitle:@"查询对象权限" forState:UIControlStateNormal];
    [_queryObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [_queryObjButton setBackgroundColor:backColor];
    [_queryObjButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_queryObjButton];
    
    // Button 删除桶
    _deleteBucketButton = [[UIButton alloc] initWithFrame:CGRectMake(20 ,50 + 5 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_deleteBucketButton setTitle:@"删除桶" forState:UIControlStateNormal];
    [_deleteBucketButton setTitleColor:textColor forState:UIControlStateNormal];
    [_deleteBucketButton setBackgroundColor:backColor];
    [_deleteBucketButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_deleteBucketButton];
    
    // Button 修改桶权限
    _updateBucketButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 5 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_updateBucketButton setTitle:@"修改桶权限" forState:UIControlStateNormal];
    [_updateBucketButton setTitleColor:textColor forState:UIControlStateNormal];
    [_updateBucketButton setBackgroundColor:backColor];
    [_updateBucketButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_updateBucketButton];
    
    // Button 设置桶版本
    _setBucketVersionButton = [[UIButton alloc] initWithFrame:CGRectMake(20 ,50 + 6 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_setBucketVersionButton setTitle:@"设置桶版本" forState:UIControlStateNormal];
    [_setBucketVersionButton setTitleColor:textColor forState:UIControlStateNormal];
    [_setBucketVersionButton setBackgroundColor:backColor];
    [_setBucketVersionButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_setBucketVersionButton];
    
    // Button 查询所有对象权限
    _queryAllObjButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 6 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_queryAllObjButton setTitle:@"查询所有对象权限" forState:UIControlStateNormal];
    [_queryAllObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [_queryAllObjButton setBackgroundColor:backColor];
    [_queryAllObjButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_queryAllObjButton];
    
    // Button 查询桶版本
    _queryBucketVersionButton = [[UIButton alloc] initWithFrame:CGRectMake(20 ,50 + 7 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_queryBucketVersionButton setTitle:@"查询桶版本" forState:UIControlStateNormal];
    [_queryBucketVersionButton setTitleColor:textColor forState:UIControlStateNormal];
    [_queryBucketVersionButton setBackgroundColor:backColor];
    [_queryBucketVersionButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_queryBucketVersionButton];
    
    // Button 查询所有对象版本
    _queryAllObjVersionButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 7 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_queryAllObjVersionButton setTitle:@"查询所有对象版本" forState:UIControlStateNormal];
    [_queryAllObjVersionButton setTitleColor:textColor forState:UIControlStateNormal];
    [_queryAllObjVersionButton setBackgroundColor:backColor];
    [_queryAllObjVersionButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_queryAllObjVersionButton];
    
    // Button 修改对象权限
    _updateObjButton = [[UIButton alloc] initWithFrame:CGRectMake(20 ,50 + 8 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_updateObjButton setTitle:@"修改对象权限" forState:UIControlStateNormal];
    [_updateObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [_updateObjButton setBackgroundColor:backColor];
    [_updateObjButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_updateObjButton];
    
    // Button 删除指定版本的对象
    _deleteObjForVersionButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 8 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_deleteObjForVersionButton setTitle:@"删除指定版本的对象" forState:UIControlStateNormal];
    [_deleteObjForVersionButton setTitleColor:textColor forState:UIControlStateNormal];
    [_deleteObjForVersionButton setBackgroundColor:backColor];
    [_deleteObjForVersionButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_deleteObjForVersionButton];
    
    // Button 下载对象
    _downloadObjButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 50 + 9 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [_downloadObjButton setTitle:@"下载对象" forState:UIControlStateNormal];
    [_downloadObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [_downloadObjButton setBackgroundColor:backColor];
    [_downloadObjButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_downloadObjButton];
    
    // Button 暂停下载
    _cancelDownloadObjButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 , 50 + 9 * (40 + 3) , (kWidth - 40)/4 - 2, 40)];
    [_cancelDownloadObjButton setTitle:@"暂停下载" forState:UIControlStateNormal];
    [_cancelDownloadObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [_cancelDownloadObjButton setBackgroundColor:backColor];
    [_cancelDownloadObjButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cancelDownloadObjButton];
    
    // Button 继续下载
    _continueDownloadObjButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 + (kWidth - 40)/4 + 2 , 50 + 9 * (40 + 3) , (kWidth - 40)/4 - 2, 40)];
    [_continueDownloadObjButton setTitle:@"继续下载" forState:UIControlStateNormal];
    [_continueDownloadObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [_continueDownloadObjButton setBackgroundColor:backColor];
    [_continueDownloadObjButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_continueDownloadObjButton];
    
    // Button 获取外链
    _getUrlButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 50 + 10 * (40 + 3) , 80, 40)];
    [_getUrlButton setTitle:@"获取外链" forState:UIControlStateNormal];
    [_getUrlButton setTitleColor:textColor forState:UIControlStateNormal];
    [_getUrlButton setBackgroundColor:backColor];
    [_getUrlButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_getUrlButton];
    
    // UILabel 外链显示
    _urlShow = [[UILabel alloc] initWithFrame:CGRectMake(120,50 + 10 * (40 + 3) , kWidth - 100, 40)];
    [_urlShow  setText:@"URL:"];
    [_urlShow  setTextAlignment:NSTextAlignmentLeft];
    [_urlShow  setTextColor:textColor];
    [_urlShow  setBackgroundColor:[UIColor yellowColor]];
    [self.view addSubview:_urlShow];
    
    // UILabel 进度显示
    _progressShow = [[UILabel alloc] initWithFrame:CGRectMake(20,50 + 11 * (40 + 3) , kWidth - 40, 40)];
    [_progressShow  setText:@"进度:"];
    [_progressShow  setTextAlignment:NSTextAlignmentLeft];
    [_progressShow  setTextColor:textColor];
    [_progressShow  setBackgroundColor:[UIColor yellowColor]];
    [self.view addSubview:_progressShow];
}

- (void)buttonAction:(UIButton *)sender {
    __weak typeof(self) weakSelf = self;
    if (YES == [sender isEqual:_pushButton]){
        NSLog(@"Click pushButton");
        _bPauseStatus = NO;
        _progressShow.text = @"进度:";
        _objShow.text = @"对象名:";
//        [self gotoImageLibrary];        // 使用 UIImagePickerController 获取相册图片
        AlbumsVC *vc = [[AlbumsVC alloc] init];
        vc.uploadView = self.view;
        self.navigationController.navigationBar.hidden = NO;
        [self.navigationController pushViewController:vc animated:YES];      // 使用 PHImageManager 获取相册图片
    } else if (YES == [sender isEqual:_takePhotoPushButton]){
        NSLog(@"takePhoto button");
        UIImagePickerController *pick = [[UIImagePickerController alloc]init];
        pick.sourceType=UIImagePickerControllerCameraCaptureModeVideo;
        //        pick.sourceType = UIImagePickerControllerSourceTypeCamera;
        pick.delegate = self;
        [self presentViewController:pick animated:YES completion:^{
            
        }];
    } else if (YES == [sender isEqual:_cancelPushButton]){
        NSLog(@"Click Cancel pushButton");
        //暂停上传
        _bPauseStatus = YES;
    } else if (YES == [sender isEqual:_continuePushButton]){
        // 继续上传
        _bPauseStatus = NO;
        [self prePush];
    }else if(YES == [sender isEqual:_createBucketButton]){
        // 创建桶
        NSLog(@"Click createBucketButton");
        NSString * newBucket = _bucketField.text;
        if(newBucket.length == 0){
            NSLog(@"bucket is null");
            return;
        }
        [_upManager createBucket:newBucket complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"创建桶 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
            
        }];
    } else if(YES == [sender isEqual:_queryBucketButton]){
        // 查询桶
        NSLog(@"Click queryBucketButton");
        NSString * queryBucket = _bucketField.text;
        if(queryBucket.length == 0){
            NSLog(@"bucket is null");
            return;
        }
        [_upManager queryBucketAcl:queryBucket complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"查询桶 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        }];
    } else if(YES == [sender isEqual:_deleteBucketButton]){
        // 删除桶
        NSLog(@"Click deleteBucketButton");
        NSString * deleteBucket = _bucketField.text;
        if(deleteBucket.length == 0){
            NSLog(@"bucket is null");
            return;
        }
        [_upManager deleteBucket:deleteBucket complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"删除桶 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        }];
    } else if(YES == [sender isEqual:_updateBucketButton]){
        // 修改桶权限
        NSLog(@"Click updateBucketButton");
        NSString * updateBucket = _bucketField.text;
        if(updateBucket.length == 0){
            NSLog(@"bucket is null");
            return;
        }
        spUpLoadOption *opt = [[spUpLoadOption alloc] initWithMime:nil progressHandler:nil
                                                            params:@{ @"x-amz-acl" : strSpBucketAclPrivate}
                                                cancellationSignal:nil];
        [_upManager updateBucketAcl:updateBucket complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"修改桶权限 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        } option:opt];
    } else if(YES == [sender isEqual:_setBucketVersionButton]){
        // 设置桶版本控制
        NSLog(@"Click setBucketVersionButton");
        NSString * versionBucket = _bucketField.text;
        if(versionBucket.length == 0){
            NSLog(@"bucket is null");
            return;
        }
        
        [_upManager setBucketVersion:versionBucket version:strSpBucketVersionEnabled complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"设置桶版本控制 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        }];
    } else if(YES == [sender isEqual:_deleteObjButton]){
        // 删除桶内对象
        NSLog(@"Click deleteObjButton");
        NSString * Bucket = _bucketField.text;
        NSString * obj = _objField.text;
        if(Bucket.length == 0 || obj.length == 0){
            NSLog(@"bucket or obj is null");
            return;
        }

        [_upManager deleteObj:Bucket obj:obj complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"删除桶内对象 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        }];
    } else if(YES == [sender isEqual:_deleteObjForVersionButton]){
        // 删除桶内指定版本的对象
        NSLog(@"Click deleteObjForVersionButton");
        NSString * Bucket = _bucketField.text;
        NSString * obj = _objField.text;
        NSString * versionId = @"versionId";
        
        if(Bucket.length == 0 || obj.length == 0){
            NSLog(@"bucket or obj is null");
            return;
        }
        
        [_upManager deleteObjForVersion:Bucket obj:obj versionId:versionId complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"删除桶内指定版本的对象 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        }];
    } else if(YES == [sender isEqual:_updateObjButton]){
        // 修改对象权限
        NSLog(@"Click updateObjButton");
        spUpLoadOption *opt = [[spUpLoadOption alloc] initWithMime:nil progressHandler:nil
                                                            params:@{ @"x-amz-acl" : strSpBucketAclPrivate}
                                                cancellationSignal:nil];
        NSString * Bucket = _bucketField.text;
        NSString * obj = _objField.text;
        
        if(Bucket.length == 0 || obj.length == 0){
            NSLog(@"bucket or obj is null");
            return;
        }
        
        [_upManager updateObj:Bucket obj:obj complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"修改对象权限 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        } option:opt];
    } else if(YES == [sender isEqual:_queryObjButton]){
        // 查询对象权限
        NSLog(@"Click updateObjButton");
        NSString * Bucket = _bucketField.text;
        NSString * obj = _objField.text;
        
        if(Bucket.length == 0 || obj.length == 0){
            NSLog(@"bucket or obj is null");
            return;
        }
        
        [_upManager queryObj:Bucket obj:obj complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"查询对象权限 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        }];
    } else if(YES == [sender isEqual:_queryAllObjButton]){
        // 查询所有对象
        NSLog(@"Click updateObjButton");
        NSString * Bucket = _bucketField.text;
        
        if(Bucket.length == 0 ){
            NSLog(@"bucket is null");
            return;
        }
        
        [_upManager queryAllObj:Bucket complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"查询所有对象 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        }];
    } else if(YES == [sender isEqual:_queryBucketVersionButton]){
        // 查询桶版本信息
        NSLog(@"Click updateObjButton");
        NSString * Bucket = _bucketField.text;
        
        if(Bucket.length == 0 ){
            NSLog(@"bucket is null");
            return;
        }
        
        [_upManager queryBucketVersion:Bucket complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"查询桶版本信息 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        }];
    } else if(YES == [sender isEqual:_queryAllObjVersionButton]){
        // 查询桶内所有对象版本信息
        NSLog(@"Click queryAllObjVersionButton");
        NSString * Bucket = _bucketField.text;
        
        if(Bucket.length == 0 ){
            NSLog(@"bucket is null");
            return;
        }
        
        [_upManager queryAllObjVersion:Bucket complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"桶内对象:%@",key);
            NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
            [weakSelf showErrorText:[NSString stringWithFormat:@"查询桶内所有对象版本信息 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@ \n info:%@", info.statusCode,info.reqId, info.error.description,[self convertToJsonData:resp]];
        }];
    } else if(YES == [sender isEqual:_downloadObjButton]){
        // 下载桶内对象
        NSLog(@"Click downloadObjButton");
        NSString * Bucket = _bucketField.text;
        NSString * obj = _objField.text;
        NSString * downloadUrl = [NSString stringWithFormat:@"http://oss-cn-shanghai.speedycloud.org/%@/%@",Bucket,obj];
        
        // sessionManager start
//        if (_downloadModel != nil && _downloadModel.state == spDownloadStateReadying) {
//            [_downManager cancleWithDownloadModel:_downloadModel];
//            return;
//        }
//
//        if ([_downManager isDownloadCompletedWithDownloadModel:_downloadModel]) {
//            [_downManager deleteFileWithDownloadModel:_downloadModel];
//        }
//        
//        if (_downloadModel.state == spDownloadStateRunning) {
//            [_downManager suspendWithDownloadModel:_downloadModel];
//            return;
//        }

        // manager里面是否有这个model是正在下载
        _downloadModel = [_downManager downLoadingModelForURLString:downloadUrl];
        if(_downloadModel == nil){
            spDownloadModel *model = [[spDownloadModel alloc]initWithURLString:downloadUrl];
            _downloadModel = model;
        }
        if (_downloadModel) {
            __weak typeof(self) weakSelf = self;
            [_downManager startWithDownloadModel:_downloadModel bucket:Bucket obj:obj progress:^(spDownloadProgress *progress) {
                NSLog(@"progress=%f",progress.progress);
                [weakSelf showProcessText:[NSString stringWithFormat:@"进度:%f%%", 100.0*progress.progress]];

            } state:^(spDownloadState state, NSString *filePath, NSError *error) {
                if (state == spDownloadStateCompleted) {
                    NSLog(@"filePath=%@",filePath);
                    [weakSelf showObjNameText:[NSString stringWithFormat:@"路径:%@",filePath]];
                }
                NSLog(@"error=%@",error.description);
                [weakSelf showErrorText:[NSString stringWithFormat:@"下载对象 返回信息=%@",error.description]];
                weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"filePath=%@ \n error=%@",filePath, error.description];
            }];
            // sessionManager end
            return;
        }
    } else if(YES == [sender isEqual:_cancelDownloadObjButton]){
        if (_downloadModel.state == spDownloadStateRunning) {
            [_downManager suspendWithDownloadModel:_downloadModel];
        }
    } else if(YES == [sender isEqual:_continueDownloadObjButton]){
        NSString * Bucket = _bucketField.text;
        NSString * obj = _objField.text;
        [_downManager resumeWithDownloadModel:_downloadModel bucket:Bucket obj:obj];
    } else if(YES == [sender isEqual:_getUrlButton]){
        NSDate * expireDate = [[NSDate alloc] initWithTimeIntervalSinceNow:15*60];
        //时间转时间戳的方法:
        NSInteger timeSp = [[NSNumber numberWithDouble:[expireDate timeIntervalSince1970]] integerValue];
        NSString * Bucket = _bucketField.text;
        NSString * obj = _objField.text;
        NSString * url = [_upManager getExternalUrl:Bucket obj:obj contentType:@"image/jpeg" expireDate:timeSp];
        NSLog(@"url:%@",url);
        [self.urlShow setText:url];
    }
}

/**
 *  调用系统相册
 */
-(void)gotoImageLibrary
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeImage,nil];
        picker.allowsEditing = NO;
        [self presentViewController:picker animated:YES completion:nil];
    }else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"访问图片库错误"
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert show];
    }
}

//再调用以下委托：
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    NSLog(@"Picker returned successfully.");
    
    NSLog(@"%@", info);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:KVideoUrlPath]) {
        [fileManager createDirectoryAtPath:KVideoUrlPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    _uploadFilePath = [NSString stringWithFormat:@"%@/%@",KVideoUrlPath,self.appfileName];
    BOOL res= [fileManager removeItemAtPath:_uploadFilePath error:nil];
    if (res) {
        NSLog(@"文件删除成功");
    }else
        NSLog(@"文件删除失败");
    NSLog(@"文件是否存在: %@",[fileManager isExecutableFileAtPath:_uploadFilePath]?@"YES":@"NO");
    
    UIImage *originImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    //    originImage=[self imageWithImage:originImage scaledToSize:CGSizeMake( 1632,1224)];

    [UIImageJPEGRepresentation(originImage, 1.0)writeToFile: _uploadFilePath atomically:YES];
    
    [picker dismissModalViewControllerAnimated:YES];
    
}

//获取当前时间戳  （以毫秒为单位）
- (NSString *)getNowTimeTimestamp{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss SSS"]; // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
    //设置时区,这个对于时间的处理有时很重要
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:timeZone];
    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]*1000];
    return timeSp;
}

-(void)showProcessText:(NSString *)showText{
//    UILabel *progressShow = [[UILabel alloc]initWithFrame:CGRectMake(20,50 + 9 * (40 + 3) , kWidth - 40, 40)];
    NSString *showInfo = [[NSString alloc] initWithFormat:@"%@",showText];
    [self.progressShow setText:showInfo];
    [self.progressShow setTextAlignment:NSTextAlignmentLeft];
    [self.progressShow setTextColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.9f alpha:1.0f]];
    [self.progressShow setBackgroundColor:[UIColor yellowColor]];
//    [self.view addSubview:progressShow];
}

-(void)showObjNameText:(NSString *)showText{
//    UILabel *objShow = [[UILabel alloc]initWithFrame:CGRectMake(20,50 + 10 * (40 + 3) , kWidth - 40, 40)];
    NSString *showInfo = [[NSString alloc] initWithFormat:@"%@",showText];
    [self.objShow setText:showInfo];
    [self.objShow setTextAlignment:NSTextAlignmentLeft];
    [self.objShow setTextColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.9f alpha:1.0f]];
    [self.objShow setBackgroundColor:[UIColor yellowColor]];
//    [self.view addSubview:objShow];
}

-(void)showErrorText:(NSString *)showText{
//    UILabel *errorShow = [[UILabel alloc]initWithFrame:CGRectMake(20,50 + 11 * (40 + 3) , kWidth - 100, 40)];
    NSString *showInfo = [[NSString alloc] initWithFormat:@"返回信息:%@",showText];
    [self.errorShow setText:showInfo];
    [self.errorShow setTextAlignment:NSTextAlignmentLeft];
    [self.errorShow setTextColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.9f alpha:1.0f]];
    [self.errorShow setBackgroundColor:[UIColor yellowColor]];
    self.uploadFilePath = @"";
//    [self.view addSubview:errorShow];
}

-(void)prePush{
    NSString * bucket = self.bucketField.text;
    NSString * obj = self.objField.text;
    
    __weak typeof(self) weakSelf = self;
    [_upManager uploadFile:bucket obj:obj filePath:_uploadFilePath complete:^(spResponseInfo *info, NSString *key, NSDictionary *resp) {
        NSLog(@"桶内对象:%@",key);
        NSLog(@"resCode:%d,reqId:%@,error.des:%@", info.statusCode,info.reqId, info.error.description);
        for (NSString *key in resp) {
            NSLog(@"key:%@--value:%@", key,resp[key]);
        }
        [weakSelf showErrorText:[NSString stringWithFormat:@"上传对象 返回码=%d 错误=%@",info.statusCode,info.error.description]];
        weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
    } option:_opt];
}

-(void)showDetailInfoClick{
    UIViewController *vc = [UIViewController new];
    
    vc.view.backgroundColor = [UIColor cyanColor];
    
    vc.view.frame = CGRectMake(0, 0, kWidth * 0.8, kHeight * 0.8);
    vc.view.layer.cornerRadius = 4.0;
    vc.view.layer.masksToBounds = YES;
    
    //设置控件lable的位置
    UILabel *lable = [[UILabel alloc] initWithFrame:vc.view.frame];
    
    //设置lable文本内容为I am UILable
    [lable setText:self.detailInfo];
    
    lable.numberOfLines = 0;
    
    //设置lable文本中的文字居中
    lable.textAlignment = NSTextAlignmentCenter;
    
    //把lable控件添加到当前的View上
    [vc.view addSubview:lable];
    
    [self cb_presentPopupViewController:vc animationType:CBPopupViewAnimationFade aligment:CBPopupViewAligmentCenter dismissed:nil];
}

-(NSString *)convertToJsonData:(NSDictionary *)dict{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    if (!jsonData) {
        NSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return mutStr;
}

- (IBAction)endEditing:(id)sender{
    [_bucketField resignFirstResponder];
    [_objField resignFirstResponder];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
