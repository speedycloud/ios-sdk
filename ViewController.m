//
//  ViewController.m
//  SpeedyCloud
//
//  Created by 郭煌 on 2017/4/17.
//  Copyright © 2017年 SpeedyCloud. All rights reserved.
//

#import "ViewController.h"
#import "SCObjectStorage.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    SCObjectStorage *objectStorage = [[SCObjectStorage alloc] initWithKeySecret:@"5C0FA427C421219C0D67FF372AB71784" secret:@"d519b8b1a9c0cc51100ccff69a3f574c87ba2969ab7f8a8f30d243a8d5d7d69b"];
    
    NSString *bucket = @"ddsfsd";
    NSString *key = @"ddf";
    
//    [objectStorage createBucket:bucket];
//    [objectStorage deleteBucket:bucket];
//    [objectStorage queryBucketAcl:bucket];
//    [objectStorage updateBucketAcl:bucket acl:@"private"];
    
//    [objectStorage setBucketVersioning:bucket status:@"Enabled"];
//    [objectStorage queryBucketVersioning:bucket];
  
    /*
    NSString *str = @"This is a test exampledsdsddssddsdssddssddsdsddssdsdsdsdsdsd";
    NSData *data = [str dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    [objectStorage createObject:bucket key:key data:data];
     */
    
//    [objectStorage deleteObject:bucket key:key];
    [objectStorage queryObjectVersions:bucket];
//    [objectStorage deleteObjectVersion:bucket key:key version:@"EPKhqogjwRS1MDRFGTcDTV4bt1nTywO"];
    
//    [objectStorage queryObjectAcl:bucket key:key];
//    [objectStorage updateObjectAcl:bucket key:key acl:@"private"];
//    [objectStorage queryAllObjects:bucket];
//    [objectStorage downloadObject:bucket key:key];
    
//    [objectStorage uploadBigObjectStep1:bucket key:key];
//    [objectStorage uploadBigObjectStep2:bucket key:key step:1 uploadId:@"2~iv1SOV3uYrEDDqFWfBWDWXFllNS6-7Z" data:data];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
