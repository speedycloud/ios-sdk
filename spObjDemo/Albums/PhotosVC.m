//
//  PhotosVC.m
//  Photos使用
//
//  Created by 软件开发部2 on 2018/3/22.
//  Copyright © 2018年 软件开发部2. All rights reserved.
//

#import "PhotosVC.h"
#import "ShowVC.h"
#import "PhotosTool.h"
#import "PhotoCell.h"

@interface PhotosVC ()<UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic,strong) NSArray *datas;
@end

@implementation PhotosVC

#pragma mark - life cycle
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadData];
    
}
- (void)loadData {
    [[PhotosTool sharedTool] requestAssetsWithCollection:_collection andHandler:^(BOOL result, NSArray *datas) {
        self.datas = datas;
        [self.collectionView reloadData];
    }];
}

- (void)setupUI {
    CGFloat width = [UIScreen mainScreen].bounds.size.width * 0.5;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(width, width);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout: layout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor whiteColor];
    [_collectionView registerNib:[UINib nibWithNibName:@"PhotoCell" bundle:nil] forCellWithReuseIdentifier:@"PhotoCell"];
    [self.view addSubview:_collectionView];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.datas.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = nil;
    if (indexPath.item < self.datas.count) {
        asset = self.datas[indexPath.item];
    }
    PhotoCell *cell = [[PhotoCell alloc] initWithCollectionView:collectionView andIndexPath:indexPath andAsset:asset];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCell *cell = (PhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    ShowVC *vc = [[ShowVC alloc] init];
    vc.asset = cell.asset;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
