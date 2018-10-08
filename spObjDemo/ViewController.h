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
@property NSString *uploadFilePath;
@property NSString *detailInfo;
@property spUpLoadOption *opt;
@property spObjUpLoadManager *upManager;
@property BOOL bPauseStatus;

@end

