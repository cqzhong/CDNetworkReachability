//
//  CDViewController.m
//  CDNetworkReachability
//
//  Created by cqzhong on 09/21/2019.
//  Copyright (c) 2019 cqzhong. All rights reserved.
//

#import "CDViewController.h"

#import "CDNetworkReachability.h"

@interface CDViewController ()

@end

@implementation CDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CDNetworkReachability *reachability = [CDNetworkReachability manager];
    //[CDNetworkReachability reachabilityWithHostName:@"www.baidu.com"];
    [reachability startNotifier];
    
    //获取当前网络状态
    [reachability currentReachabilityStatus];
    
    [[CDNetworkReachability manager] setReachabilityStatusChangeBlock:^(CDNetworkStatus status) {
        
    }];
    
    [[CDNetworkReachability manager] checkNetworkPermissionsEvent:^(CDNetworkAuthorizationStatus status) {
        
        if (status == CDNetworkAuthorizationRestricted) {
            //没有网络授权
            
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
