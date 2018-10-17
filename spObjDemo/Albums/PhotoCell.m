//
//  PhotoCell.m
//  Photos使用
//
//  Created by 软件开发部2 on 2018/3/22.
//  Copyright © 2018年 软件开发部2. All rights reserved.
//

#import "PhotoCell.h"
#import "PhotosTool.h"
@interface PhotoCell()
@property (weak, nonatomic) IBOutlet UIImageView *poster;


@end

@implementation PhotoCell
#pragma mark - life cycle
- (void)awakeFromNib {
    [super awakeFromNib];

}
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView andIndexPath:(NSIndexPath *)indexPath andAsset:(PHAsset *)asset{
    self = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    self.asset = asset;
    return self;
}
- (void)setAsset:(PHAsset *)asset {
    _asset = asset;
    [[PhotosTool sharedTool] requestImgaeWithSize:CGSizeMake(200, 200) andAsset:_asset andCompletionHandler:^(UIImage *result) {
        _poster.image = result;
    }];
}
@end
