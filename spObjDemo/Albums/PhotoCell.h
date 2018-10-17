//
//  PhotoCell.h
//  Photos使用
//
//  Created by 软件开发部2 on 2018/3/22.
//  Copyright © 2018年 软件开发部2. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PHAsset;
@interface PhotoCell : UICollectionViewCell
@property (nonatomic,strong) PHAsset *asset;
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView andIndexPath:(NSIndexPath *)indexPath andAsset:(PHAsset *)asset;
@end
