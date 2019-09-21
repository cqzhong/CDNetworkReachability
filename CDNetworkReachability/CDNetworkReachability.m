//
//  CDNetworkReachability.m
//  CDNetworkReachability_Example
//
//  Created by cqz on 2018/12/17.
//  Copyright © 2018 cqz. All rights reserved.
//

#import "CDNetworkReachability.h"

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCellularData.h>
#import <SystemConfiguration/CaptiveNetwork.h>

#import <netdb.h>
#import <sys/socket.h>
#import <netinet/in.h>



NSString *kNetworkReachabilityChangedNotification = @"kNetworkReachabilityChangedNotification";
NSString *kNetworkReachabilityStatusKey = @"kNetworkReachabilityStatusKey";

/// 通过状态栏判断网络类型
typedef NS_ENUM(NSInteger, CDNetworkType) {
    
    CDNetworkTypeUnknown,      /// 未知
    CDNetworkTypeOffline,      /// 飞行模式
    CDNetworkTypeWiFi,         /// Wi-Fi
    CDNetworkTypeCellularData, /// 蜂窝
};

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info);

typedef void(^CDNetworkReachabilityBlock)(CDNetworkStatus status);

@interface CDNetworkReachability()

@property (nonatomic, copy) CDNetworkReachabilityBlock reachabilityBlock;
@property (nonatomic, copy) CDNetworkPermissionsStatusHandel permissionsHandel;

@end

@implementation CDNetworkReachability
{
    SCNetworkReachabilityRef _reachabilityRef;
    CTCellularData *_cellularData NS_AVAILABLE_IOS(9_0);

}
+ (instancetype)manager {
    
    static CDNetworkReachability *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self reachabilityForInternetConnection];
    });
    return instance;
}
+ (instancetype)reachabilityWithHostName:(NSString *)hostName {

    CDNetworkReachability *returnValue = NULL;
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
    if (reachability != NULL) {
        returnValue = [[self alloc] init];
        if (returnValue != NULL) {
            returnValue->_reachabilityRef = reachability;
        } else {
            CFRelease(reachability);
        }
    }
    return returnValue;
}

+ (instancetype)reachabilityWithAddress:(const struct sockaddr *)hostAddress {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, hostAddress);
    
    CDNetworkReachability* returnValue = NULL;
    
    if (reachability != NULL)
    {
        returnValue = [[self alloc] init];
        if (returnValue != NULL)
        {
            returnValue->_reachabilityRef = reachability;
        }
        else {
            CFRelease(reachability);
        }
    }
    return returnValue;
}

+ (instancetype)reachabilityForInternetConnection
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    return [self reachabilityWithAddress: (const struct sockaddr *) &zeroAddress];
}

- (BOOL)startNotifier {
    
    BOOL returnValue = NO;
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context)) {
        
        ///此行代码会触发系统弹出权限询问框
        if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
            
            returnValue = true;
        }
    }
    return returnValue;
}
- (void)setReachabilityStatusChangeBlock:(nullable void (^)(CDNetworkStatus status))block
{
    self.reachabilityBlock = block;
}
- (CDNetworkStatus)currentReachabilityStatus
{
    CDNetworkStatus returnValue = CDNetworkStatusNotReachable;
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags))
    {
        returnValue = [self networkStatusForFlags:flags];
    }
    
    return returnValue;
}
- (void)callBackForCurrentStatus
{
    CDNetworkStatus status = self.currentReachabilityStatus;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkReachabilityChangedNotification object:self userInfo:@{kNetworkReachabilityStatusKey : @(status)}];
    if (self.reachabilityBlock) {
        
        self.reachabilityBlock(status);
    }
}
- (CDNetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags
{
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
    {
        /*** 网络不通
         *** 1、未打开任何数据连接（Wi-Fi 蜂窝数据）或者开启了飞行模式
         *** 2、网络权限被关闭
         ***/
        ///这里要判断出用户是否 开启了 Wi-Fi 或者 蜂窝数据，如果都不是那必定是网络权限被关闭。
        // The target host is not reachable.
        return CDNetworkStatusNotReachable;
    }
    
    CDNetworkStatus returnValue = CDNetworkStatusNotReachable;
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        /*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
        returnValue = CDNetworkStatusWiFi;
    }
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            /*
             ... and no [user] intervention is needed...
             */
            returnValue = CDNetworkStatusWiFi;
        }
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        /*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
        NSArray *typeStrings2G = @[CTRadioAccessTechnologyEdge,
                                   CTRadioAccessTechnologyGPRS,
                                   CTRadioAccessTechnologyCDMA1x];
        
        NSArray *typeStrings3G = @[CTRadioAccessTechnologyHSDPA,
                                   CTRadioAccessTechnologyWCDMA,
                                   CTRadioAccessTechnologyHSUPA,
                                   CTRadioAccessTechnologyCDMAEVDORev0,
                                   CTRadioAccessTechnologyCDMAEVDORevA,
                                   CTRadioAccessTechnologyCDMAEVDORevB,
                                   CTRadioAccessTechnologyeHRPD];
        
        NSArray *typeStrings4G = @[CTRadioAccessTechnologyLTE];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            CTTelephonyNetworkInfo *teleInfo= [[CTTelephonyNetworkInfo alloc] init];
            NSString *accessString = teleInfo.currentRadioAccessTechnology;
            if ([typeStrings4G containsObject:accessString]) {
                return CDNetworkStatusWWAN4G;
            } else if ([typeStrings3G containsObject:accessString]) {
                return CDNetworkStatusWWAN3G;
            } else if ([typeStrings2G containsObject:accessString]) {
                return CDNetworkStatusWWAN2G;
            } else {
                return CDNetworkStatusUnknown;
            }
        } else {
            return CDNetworkStatusUnknown;
        }
    }
    
    return returnValue;
}

- (void)stopNotifier
{
    if (_reachabilityRef != NULL)
    {
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

- (void)dealloc
{
    [self stopNotifier];
    if (_reachabilityRef != NULL)
    {
        CFRelease(_reachabilityRef);
    }
}


/// MARK: -判断网络数据是否授权
- (void)checkNetworkPermissionsEvent:(void (^)(CDNetworkAuthorizationStatus status))block{
    
    _permissionsHandel = block;
    [self startCheckEvent];
}
///检测用户是否存在网络代理
-(BOOL)configureProxies {
    NSDictionary *proxySettings = CFBridgingRelease(CFNetworkCopySystemProxySettings());
    
    NSArray *proxies = nil;
    
    NSURL *url = [[NSURL alloc] initWithString:@"http://api.m.taobao.com"];
    
    proxies = CFBridgingRelease(CFNetworkCopyProxiesForURL((__bridge CFURLRef)url,
                                                           (__bridge CFDictionaryRef)proxySettings));
    if (proxies.count > 0)
    {
        NSDictionary *settings = [proxies objectAtIndex:0];
        NSString *host = [settings objectForKey:(NSString *)kCFProxyHostNameKey];
        NSString *port = [settings objectForKey:(NSString *)kCFProxyPortNumberKey];
        
        if (host || port)
        {
            return true;
        }
    }
    return false;
}

- (void)startCheckEvent {

    if ([UIDevice currentDevice].systemVersion.floatValue < 10.0 || [self currentReachable]) {
        /** iOS 10 以下 不够用检测默认通过 **/
        
        /** 先用 currentReachable 判断，若返回的为 YES 则说明：
         1. 用户选择了 「WALN 与蜂窝移动网」并处于其中一种网络环境下。
         2. 用户选择了 「WALN」并处于 WALN 网络环境下。
         
         此时是有网络访问权限的，直接返回 CDNetworkAuthorizationAccessible
         **/
        [self notiWithAccessibleState:CDNetworkAuthorizationAccessible];
        return;
    }
    
    CTCellularDataRestrictedState status = kCTCellularDataRestrictedStateUnknown;
    if (@available(iOS 9.0, *)) status = _cellularData.restrictedState;
    
    switch (status) {
        case kCTCellularDataRestricted: {/// 系统 API 返回 无蜂窝数据访问权限
            
            [self getCurrentNetworkType:^(CDNetworkType type) {
                
                /**  若用户是通过蜂窝数据 或 WLAN 上网，走到这里来 说明权限被关闭**/
                
                if (type == CDNetworkTypeCellularData || type == CDNetworkTypeWiFi) {
                    
                    [self notiWithAccessibleState:CDNetworkAuthorizationRestricted];
                } else {  /// 可能开了飞行模式，无法判断
                    [self notiWithAccessibleState:CDNetworkAuthorizationUnknown];
                }
            }];
            break;
        }
        case kCTCellularDataNotRestricted: /// 系统 API 访问有有蜂窝数据访问权限，那就必定有 Wi-Fi 数据访问权限
            [self notiWithAccessibleState:CDNetworkAuthorizationAccessible];
            break;
        case kCTCellularDataRestrictedStateUnknown: {
            /// CTCellularData 刚开始初始化的时候，可能会拿到 kCTCellularDataRestrictedStateUnknown 延迟一下再试就好了
            //网线连接获取不到IP地址，和状态栏网络标示
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [self startCheckEvent];
            });
            break;
        }
        default:
            break;
    };
}
- (BOOL)currentReachable {
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(self->_reachabilityRef, &flags)) {
        if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)  return false;
        
        return true;
    }
    return false;
}
/// MARK: -得到当前的网络状态
- (void)getCurrentNetworkType:(void(^)(CDNetworkType))block {
    
    if ([self isWiFiEnable]) return block(CDNetworkTypeWiFi);
    
    CDNetworkType type = [self getNetworkTypeFromStatusBar];
    if (type == CDNetworkTypeWiFi) {
        /// 这时候从状态栏拿到的是 Wi-Fi 说明状态栏没有刷新，延迟一会再获取
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self getCurrentNetworkType:block];
        });
    }
    block(type);
}
/// 从状态栏拿网络标示比对
- (CDNetworkType)getNetworkTypeFromStatusBar {
    NSUInteger type = 0;
    @try {
        UIApplication *app = [UIApplication sharedApplication];
        UIView *statusBar = [app valueForKeyPath:@"statusBar"];
        
        if (statusBar == nil ) return CDNetworkTypeUnknown;
        
        BOOL isModernStatusBar = [statusBar isKindOfClass:NSClassFromString(@"UIStatusBar_Modern")];
        
        if (isModernStatusBar) { /// 在 iPhone X 上 statusBar 属于 UIStatusBar_Modern ，需要特殊处理
            id currentData = [statusBar valueForKeyPath:@"statusBar.currentData"];
            BOOL wifiEnable = [[currentData valueForKeyPath:@"_wifiEntry.isEnabled"] boolValue];
            
            // 这里不能用 _cellularEntry.isEnabled 来判断，该值即使关闭仍然有是 true
            BOOL cellularEnable = [[currentData valueForKeyPath:@"_cellularEntry.type"] boolValue];
            return  wifiEnable ? CDNetworkTypeWiFi : (cellularEnable ? CDNetworkTypeCellularData : CDNetworkTypeOffline);
        } else { /// 传统的 statusBar
            NSArray *children = [[statusBar valueForKeyPath:@"foregroundView"] subviews];
            for (id child in children) {
                if ([child isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
                   
                    // type == 1  => 2G
                    // type == 2  => 3G
                    // type == 3  => 4G
                    /// type == 4  => LTE  猜测为5G
                    // type == 5  => Wi-Fi
                    type = [[child valueForKeyPath:@"dataNetworkType"] intValue];
                }
            }
            return type == 0 ? CDNetworkTypeOffline : (type == 5 ? CDNetworkTypeWiFi : CDNetworkTypeCellularData);
        }
    } @catch (NSException *exception) {
        
    }
    return 0;
}

/// MARK: - 判断用户是否连接到 Wi-Fi
- (BOOL)isWiFiEnable {
    NSArray *interfaces = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    if (!interfaces) {
        return false;
    }
    NSDictionary *info = nil;
    for (NSString *ifnam in interfaces) {
        info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) { break; }
    }
    return (info != nil);
}

/// MARK: 查询权限回调
- (void)notiWithAccessibleState:(CDNetworkAuthorizationStatus)status {

 /// 此处判断网络数据未授权
    if (self.permissionsHandel) {
        self.permissionsHandel(status);
    }
}

@end
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    CDNetworkReachability *networkObject = (__bridge CDNetworkReachability *)info;
    [networkObject callBackForCurrentStatus];
    
}
