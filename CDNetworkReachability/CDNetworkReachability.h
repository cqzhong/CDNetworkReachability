//
//  CDNetworkReachability.h
//  CDNetworkReachability_Example
//
//  Created by cqz on 2018/12/17.
//  Copyright © 2018 cqz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CDNetworkStatus) {
    CDNetworkStatusNotReachable = 0,
    CDNetworkStatusUnknown = 1,
    CDNetworkStatusWWAN2G = 2,
    CDNetworkStatusWWAN3G = 3,
    CDNetworkStatusWWAN4G = 4,
    
    CDNetworkStatusWiFi = 9,
};

typedef NS_ENUM(NSUInteger, CDNetworkAuthorizationStatus) {
    
    CDNetworkAuthorizationChecking  = 0,
    CDNetworkAuthorizationUnknown     ,
    CDNetworkAuthorizationAccessible  , ///有权限
    CDNetworkAuthorizationRestricted  , ///无授权
};

typedef void(^CDNetworkPermissionsStatusHandel)(CDNetworkAuthorizationStatus status);

FOUNDATION_EXTERN NSString *kNetworkReachabilityChangedNotification;
FOUNDATION_EXTERN NSString *kNetworkReachabilityStatusKey;

@interface CDNetworkReachability : NSObject
    
//  reachabilityForInternetConnection
+ (instancetype)manager;
/*!
* Use to check the reachability of a given host name.
*/
+ (instancetype)reachabilityWithHostName:(NSString *)hostName;
    
/*!
* Use to check the reachability of a given IP address.
*/
+ (instancetype)reachabilityWithAddress:(const struct sockaddr *)hostAddress;
    
/*!
* Checks whether the default route is available. Should be used by applications that do not connect to a particular host.
*/
+ (instancetype)reachabilityForInternetConnection;
    
- (BOOL)startNotifier;
    
- (void)stopNotifier;
    
    
- (void)setReachabilityStatusChangeBlock:(nullable void (^)(CDNetworkStatus status))block;
    
- (CDNetworkStatus)currentReachabilityStatus;
    
    
/**
检测网络数据是否授权
*/
- (void)checkNetworkPermissionsEvent:(void (^)(CDNetworkAuthorizationStatus status))block;
    
    
/**
检测用户是否存在网络代理
     
@return true 是  false 否
 */
-(BOOL)configureProxies;

@end

NS_ASSUME_NONNULL_END
