//
//  PhotosVC.h
//  Photos使用
//
//  Created by 软件开发部2 on 2018/3/22.
//  Copyright © 2018年 软件开发部2. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PHAssetCollection;
@interface PhotosVC : UIViewController
@property (nonatomic,strong) PHAssetCollection *collection;
@property (nonatomic,strong) UIViewController *photoUploadView;
@end
