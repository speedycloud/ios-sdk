//
//  AlbumsVC.m
//  Photos使用
//
//  Created by 软件开发部2 on 2018/3/22.
//  Copyright © 2018年 软件开发部2. All rights reserved.
//

#import "AlbumsVC.h"
#import "PhotosVC.h"
#import "PhotosTool.h"
@interface AlbumsVC ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic,strong) UITableView *listTable;
@property (nonatomic,strong) NSArray *datas;

@end
@implementation AlbumsVC
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadData];
    
}
- (void)loadData {
    [[PhotosTool sharedTool] requestCollectionWithHandler:^(BOOL result, NSArray *datas) {
        self.datas = datas;
        [self.listTable reloadData];
    }];
}

- (void)setupUI {
    _listTable = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _listTable.delegate = self;
    _listTable.dataSource = self;
    [self.view addSubview:_listTable];
    
}
#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.datas.count;
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.00001f;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.00001f;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    PHAssetCollection *collection = nil;
    if (indexPath.row < self.datas.count) {
        collection = self.datas[indexPath.row];
    }
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    cell.textLabel.text = collection.localizedTitle;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PHAssetCollection *collection = nil;
    if (indexPath.row < self.datas.count) {
        collection = self.datas[indexPath.row];
    }
    PhotosVC *vc = [[PhotosVC alloc] init];
    vc.collection = collection;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
