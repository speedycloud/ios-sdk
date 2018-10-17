//
//  ViewController.h
//  spObjDemo
//
//  Created by YanBo on 2018/3/11.
//  Copyright © 2018年 YanBo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "spObjUpLoadManager.h"
#import "UIViewController+CBPopup.h"

@interface ViewController : UIViewController

@property NSString *appfileName;
@property UITextField *bucketField;
@property UITextField *objField;
@property (nonatomic,strong) NSString *uploadFilePath;
@property NSString *detailInfo;
@property spUpLoadOption *opt;
@property spObjUpLoadManager *upManager;
@property BOOL bPauseStatus;

@property UIButton *pushButton;
@property UIButton *takePhotoPushButton;
@property UIButton *cancelPushButton;
@property UIButton *continuePushButton;
@property UIButton *scanButton;
@property UIButton *queryBucketButton;
@property UIButton *createBucketButton;
@property UIButton *deleteBucketButton;
@property UIButton *updateBucketButton;
@property UIButton *setBucketVersionButton;
@property UIButton *deleteObjButton;
@property UIButton *deleteObjForVersionButton;
@property UIButton *updateObjButton;
@property UIButton *queryObjButton;
@property UIButton *queryAllObjButton;
@property UIButton *queryBucketVersionButton;
@property UIButton *queryAllObjVersionButton;
@property UIButton *downloadObjButton;
@property UIButton *cancelDownloadObjButton;
@property UIButton *continueDownloadObjButton;
@property UIButton *getUrlButton;
@property UILabel *urlShow;
@property UILabel *objShow;
@property UILabel *progressShow;
@property UILabel *errorShow;

@end

