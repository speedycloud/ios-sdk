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

#import <MediaPlayer/MediaPlayer.h>

//图片存储路径
#define KVideoUrlPath   \
[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"VideoURL"]
#define kHeight [[UIScreen mainScreen] bounds].size.height
#define kWidth  [[UIScreen mainScreen] bounds].size.width

#define ACCESSKEY @"your accessKey"
#define SECRETKEY @"your secretKey"

@interface ViewController ()<spDownloadDelegate>

@property (weak, nonatomic) IBOutlet UITextField *filePathField;
@property (weak, nonatomic) IBOutlet UITextField *bucketField;
@property (weak, nonatomic) IBOutlet UITextField *objField;
@property (weak, nonatomic) IBOutlet UIButton *pushButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelPushButton;
@property (weak, nonatomic) IBOutlet UIButton *continuePushButton;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UIButton *queryBucketButton;
@property (weak, nonatomic) IBOutlet UIButton *createBucketButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteBucketButton;
@property (weak, nonatomic) IBOutlet UIButton *updateBucketButton;
@property (weak, nonatomic) IBOutlet UIButton *setBucketVersionButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteObjButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteObjForVersionButton;
@property (weak, nonatomic) IBOutlet UIButton *updateObjButton;
@property (weak, nonatomic) IBOutlet UIButton *queryObjButton;
@property (weak, nonatomic) IBOutlet UIButton *queryAllObjButton;
@property (weak, nonatomic) IBOutlet UIButton *queryBucketVersionButton;
@property (weak, nonatomic) IBOutlet UIButton *queryAllObjVersionButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadObjButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelDownloadObjButton;
@property (weak, nonatomic) IBOutlet UIButton *continueDownloadObjButton;
@property (weak, nonatomic) IBOutlet UIButton *getUrlButton;
@property (weak, nonatomic) IBOutlet UILabel *urlShow;
@property (weak, nonatomic) IBOutlet UILabel *objShow;
@property (weak, nonatomic) IBOutlet UILabel *progressShow;
@property (weak, nonatomic) IBOutlet UILabel *errorShow;

@property (nonatomic,strong) spDownloadModel *downloadModel;
@property spDownloadSessionManager *downManager;

@end

@implementation ViewController

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
    [self.objShow setFrame:CGRectMake(20,50 + 12 * (40 + 3) , kWidth - 40, 40)];
    [self.objShow setText:@"对象名:"];
    [self.objShow setTextAlignment:NSTextAlignmentLeft];
    [self.objShow setTextColor:textColor];
    [self.objShow setBackgroundColor:[UIColor yellowColor]];
    [self.view addSubview:self.objShow];
    
    // UILabel 错误显示
    [self.errorShow setFrame:CGRectMake(20,50 + 13 * (40 + 3) , kWidth - 100, 40)];
    [self.errorShow setText:@"返回信息:"];
    [self.errorShow setTextAlignment:NSTextAlignmentLeft];
    [self.errorShow setTextColor:textColor];
    [self.errorShow setBackgroundColor:[UIColor yellowColor]];
    [self.view addSubview:self.errorShow];
    
    // UILabel 详细..
    UIButton * detailShow = [[UIButton alloc]initWithFrame:CGRectMake(20 + kWidth - 98,50 + 13 * (40 + 3) , 58, 40)];
    [detailShow setTitle:@"详细..." forState:UIControlStateNormal];
    [detailShow setTitleColor:textColor forState:UIControlStateNormal];
    [detailShow setBackgroundColor:[UIColor yellowColor]];
    [detailShow addTarget:self action:@selector(showDetailInfoClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:detailShow];
    
    _filePathField.enabled = NO;
    [_bucketField becomeFirstResponder];
    self.appfileName = @"newupload.jpeg";// 必须设置
    _bucketField.text = @"iosbucketsh";
    _objField.text = @"iosobjtest.jpeg";
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
    [self.bucketField setFrame:CGRectMake(20 + 80 + 3 ,50 , kWidth - 40 - 80 -3, 40)];
    [self.bucketField setPlaceholder:@"请输入桶名"];
    [self.bucketField setTextColor:textColor];
    [self.bucketField setBackgroundColor:[UIColor whiteColor]];
    
    // Edit 对象名
    [self.objField setFrame:CGRectMake(20 + 80 + 3 ,50 + 40 + 3, kWidth - 40 - 80 -3, 40)];
    [self.objField setPlaceholder:@"请输入对象名"];
    [self.objField setTextColor:textColor];
    [self.objField setBackgroundColor:[UIColor whiteColor]];
    
    // Button 创建桶
    [self.createBucketButton setFrame:CGRectMake(20 ,50 + 2*(40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.createBucketButton setTitle:@"创建桶" forState:UIControlStateNormal];
    [self.createBucketButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.createBucketButton setBackgroundColor:backColor];
    
    // Button 查询桶权限
    [self.queryBucketButton setFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 2*(40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.queryBucketButton setTitle:@"查询桶权限" forState:UIControlStateNormal];
    [self.queryBucketButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.queryBucketButton setBackgroundColor:backColor];
    
    // Button 上传对象
    [self.pushButton setFrame:CGRectMake(20 ,50 + 3*(40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.pushButton setTitle:@"上传对象" forState:UIControlStateNormal];
    [self.pushButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.pushButton setBackgroundColor:backColor];
    
    // Button 暂停上传
    [self.cancelPushButton setFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 3*(40 + 3) , (kWidth - 40)/4 - 2, 40)];
    [self.cancelPushButton setTitle:@"暂停上传" forState:UIControlStateNormal];
    [self.cancelPushButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.cancelPushButton setBackgroundColor:backColor];
    
    // Button 继续上传
    [self.continuePushButton setFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 + (kWidth - 40)/4 + 2 ,50 + 3*(40 + 3) , (kWidth - 40)/4 - 2, 40)];
    [self.continuePushButton setTitle:@"继续上传" forState:UIControlStateNormal];
    [self.continuePushButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.continuePushButton setBackgroundColor:backColor];
    
    // Button 删除对象
    [self.deleteObjButton setFrame:CGRectMake(20 ,50 + 4 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.deleteObjButton setTitle:@"删除对象" forState:UIControlStateNormal];
    [self.deleteObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.deleteObjButton setBackgroundColor:backColor];
    
    // Button 查询对象权限
    [self.queryObjButton setFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 4 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.queryObjButton setTitle:@"查询对象权限" forState:UIControlStateNormal];
    [self.queryObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.queryObjButton setBackgroundColor:backColor];
    
    // Button 删除桶
    [self.deleteBucketButton setFrame:CGRectMake(20 ,50 + 5 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.deleteBucketButton setTitle:@"删除桶" forState:UIControlStateNormal];
    [self.deleteBucketButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.deleteBucketButton setBackgroundColor:backColor];
    
    // Button 修改桶权限
    [self.updateBucketButton setFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 5 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.updateBucketButton setTitle:@"修改桶权限" forState:UIControlStateNormal];
    [self.updateBucketButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.updateBucketButton setBackgroundColor:backColor];
    
    // Button 设置桶版本
    [self.setBucketVersionButton setFrame:CGRectMake(20 ,50 + 6 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.setBucketVersionButton setTitle:@"设置桶版本" forState:UIControlStateNormal];
    [self.setBucketVersionButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.setBucketVersionButton setBackgroundColor:backColor];
    
    // Button 查询所有对象权限
    [self.queryAllObjButton setFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 6 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.queryAllObjButton setTitle:@"查询所有对象权限" forState:UIControlStateNormal];
    [self.queryAllObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.queryAllObjButton setBackgroundColor:backColor];
    
    // Button 查询桶版本
    [self.queryBucketVersionButton setFrame:CGRectMake(20 ,50 + 7 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.queryBucketVersionButton setTitle:@"查询桶版本" forState:UIControlStateNormal];
    [self.queryBucketVersionButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.queryBucketVersionButton setBackgroundColor:backColor];
    
    // Button 查询所有对象版本
    [self.queryAllObjVersionButton setFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 7 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.queryAllObjVersionButton setTitle:@"查询所有对象版本" forState:UIControlStateNormal];
    [self.queryAllObjVersionButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.queryAllObjVersionButton setBackgroundColor:backColor];
    
    // Button 修改对象权限
    [self.updateObjButton setFrame:CGRectMake(20 ,50 + 8 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.updateObjButton setTitle:@"修改对象权限" forState:UIControlStateNormal];
    [self.updateObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.updateObjButton setBackgroundColor:backColor];
    
    // Button 删除指定版本的对象
    [self.deleteObjForVersionButton setFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 ,50 + 8 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.deleteObjForVersionButton setTitle:@"删除指定版本的对象" forState:UIControlStateNormal];
    [self.deleteObjForVersionButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.deleteObjForVersionButton setBackgroundColor:backColor];
    
    // Button 下载对象
    [self.downloadObjButton setFrame:CGRectMake(20, 50 + 9 * (40 + 3) , (kWidth - 40)/2 - 2, 40)];
    [self.downloadObjButton setTitle:@"下载对象" forState:UIControlStateNormal];
    [self.downloadObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.downloadObjButton setBackgroundColor:backColor];
    
    // Button 暂停下载
    [self.cancelDownloadObjButton setFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 , 50 + 9 * (40 + 3) , (kWidth - 40)/4 - 2, 40)];
    [self.cancelDownloadObjButton setTitle:@"暂停下载" forState:UIControlStateNormal];
    [self.cancelDownloadObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.cancelDownloadObjButton setBackgroundColor:backColor];
    
    // Button 继续下载
    [self.continueDownloadObjButton setFrame:CGRectMake(20 + (kWidth - 40)/2 + 2 + (kWidth - 40)/4 + 2 , 50 + 9 * (40 + 3) , (kWidth - 40)/4 - 2, 40)];
    [self.continueDownloadObjButton setTitle:@"继续下载" forState:UIControlStateNormal];
    [self.continueDownloadObjButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.continueDownloadObjButton setBackgroundColor:backColor];
    
    // Button 获取外链
    [self.getUrlButton setFrame:CGRectMake(20, 50 + 10 * (40 + 3) , 80, 40)];
    [self.getUrlButton setTitle:@"获取外链" forState:UIControlStateNormal];
    [self.getUrlButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.getUrlButton setBackgroundColor:backColor];
    
    // UILabel 外链显示
    [self.urlShow setFrame:CGRectMake(120,50 + 10 * (40 + 3) , kWidth - 100, 40)];
    [self.urlShow  setText:@"URL:"];
    [self.urlShow  setTextAlignment:NSTextAlignmentLeft];
    [self.urlShow  setTextColor:textColor];
    [self.urlShow  setBackgroundColor:[UIColor yellowColor]];
    
    // UILabel 进度显示
    [self.progressShow setFrame:CGRectMake(20,50 + 11 * (40 + 3) , kWidth - 40, 40)];
    [self.progressShow  setText:@"进度:"];
    [self.progressShow  setTextAlignment:NSTextAlignmentLeft];
    [self.progressShow  setTextColor:textColor];
    [self.progressShow  setBackgroundColor:[UIColor yellowColor]];
//    [self.view addSubview:self.progressShow];
}

- (IBAction)buttonAction:(UIButton *)sender {
    __weak typeof(self) weakSelf = self;
    if (YES == [sender isEqual:_pushButton]){
        NSLog(@"Click pushButton");
        _bPauseStatus = NO;
        _progressShow.text = @"进度:";
        _objShow.text = @"对象名:";
        [self gotoImageLibrary];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
            [weakSelf showErrorText:[NSString stringWithFormat:@"创建桶 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
            [weakSelf showErrorText:[NSString stringWithFormat:@"查询桶 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
            [weakSelf showErrorText:[NSString stringWithFormat:@"删除桶 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
             [weakSelf showErrorText:[NSString stringWithFormat:@"修改桶权限 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
             [weakSelf showErrorText:[NSString stringWithFormat:@"设置桶版本控制 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
            [weakSelf showErrorText:[NSString stringWithFormat:@"删除桶内对象 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
            [weakSelf showErrorText:[NSString stringWithFormat:@"删除桶内指定版本的对象 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
            [weakSelf showErrorText:[NSString stringWithFormat:@"修改对象权限 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
             [weakSelf showErrorText:[NSString stringWithFormat:@"查询对象权限 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
            [weakSelf showErrorText:[NSString stringWithFormat:@"查询所有对象 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
            [weakSelf showErrorText:[NSString stringWithFormat:@"查询桶版本信息 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
            for (NSString *key in resp) {
                NSLog(@"key:%@--value:%@", key,resp[key]);
            }
             [weakSelf showErrorText:[NSString stringWithFormat:@"查询桶内所有对象版本信息 返回码=%d 错误=%@",info.statusCode,info.error.description]];
            weakSelf.detailInfo = [[NSString alloc] initWithFormat:@"resCode:%d,\n reqId:%@,\n error.des:%@", info.statusCode,info.reqId, info.error.description];
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
        NSString * url = [_upManager getExternalUrl:Bucket obj:obj contentType:@"image/jpeg" expireDate:1543593600];
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
    
    NSString *urlValue = [info valueForKey:UIImagePickerControllerReferenceURL];
    [self videoWithUrl:urlValue withFileName:self.appfileName];
    
     _uploadFilePath = [NSString stringWithFormat:@"%@/%@",KVideoUrlPath,self.appfileName];
    
    [picker dismissModalViewControllerAnimated:YES];
    
}

// 将原始视频的URL转化为NSData数据,写入沙盒
- (void)videoWithUrl:(NSURL *)url withFileName:(NSString *)fileName
{
    // 解析一下,为什么视频不像图片一样一次性开辟本身大小的内存写入?
    // 想想,如果1个视频有1G多,难道直接开辟1G多的空间大小来写?
    // 创建存放原始图的文件夹--->VideoURL
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:KVideoUrlPath]) {
        [fileManager createDirectoryAtPath:KVideoUrlPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString * videoPath = [KVideoUrlPath stringByAppendingPathComponent:fileName];
    BOOL res= [fileManager removeItemAtPath:videoPath error:nil];
    if (res) {
        NSLog(@"文件删除成功");
    }else
        NSLog(@"文件删除失败");
    NSLog(@"文件是否存在: %@",[fileManager isExecutableFileAtPath:videoPath]?@"YES":@"NO");
    
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (url) {
            [assetLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                NSString * videoPath = [KVideoUrlPath stringByAppendingPathComponent:fileName];
                const char *cvideoPath = [videoPath UTF8String];
                FILE *file = fopen(cvideoPath, "a+");
                if (file) {
                    const int bufferSize = 10 * 1024 * 1024;
                    // 初始化一个10M的buffer
                    Byte *buffer = (Byte*)malloc(bufferSize);
                    NSUInteger read = 0, offset = 0, written = 0;
                    NSError* err = nil;
                    if (rep.size != 0)
                    {
                        do {
                            read = [rep getBytes:buffer fromOffset:offset length:bufferSize error:&err];
                            written = fwrite(buffer, sizeof(char), read, file);
                            offset += read;
                        } while (read != 0 && !err);//没到结尾，没出错，ok继续
                    }
                    // 释放缓冲区，关闭文件
                    free(buffer);
                    buffer = NULL;
                    fclose(file);
                    file = NULL;
                    
                    // UI的更新记得放在主线程,要不然等子线程排队过来都不知道什么年代了,会很慢的
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self prePush];
                    });
                }
            } failureBlock:nil];
        }
    });
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
