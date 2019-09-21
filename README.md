# CDNetworkReachability

[![CI Status](https://img.shields.io/travis/cqzhong/CDNetworkReachability.svg?style=flat)](https://travis-ci.org/cqzhong/CDNetworkReachability)
[![Version](https://img.shields.io/cocoapods/v/CDNetworkReachability.svg?style=flat)](https://cocoapods.org/pods/CDNetworkReachability)
[![License](https://img.shields.io/cocoapods/l/CDNetworkReachability.svg?style=flat)](https://cocoapods.org/pods/CDNetworkReachability)
[![Platform](https://img.shields.io/cocoapods/p/CDNetworkReachability.svg?style=flat)](https://cocoapods.org/pods/CDNetworkReachability)

## Requirements
* Xcode 7 or higher
* iOS 8.0 or higher
* ARC

## Installation

CDNetworkReachability is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CDNetworkReachability'
```

### 使用方法

- 开启监测

```objc
CDNetworkReachability *reachability = [CDNetworkReachability manager];
//[CDNetworkReachability reachabilityWithHostName:@"www.baidu.com"];
[reachability startNotifier];
```

- 检测网络权限

```objc
[[CDNetworkReachability manager] checkNetworkPermissionsEvent:^(CDNetworkAuthorizationStatus status) {

if (status == CDNetworkAuthorizationRestricted) {
//没有网络授权

}
}];
```

- 获取当前网络状态

```objc
[reachability currentReachabilityStatus];
```


- 网络状态发生变化的回调

```objc
[[CDNetworkReachability manager] setReachabilityStatusChangeBlock:^(CDNetworkStatus status) {

}];
```

## Author

cqzhong, 2863802082@qq.com

## License

CDNetworkReachability is available under the MIT license. See the LICENSE file for more info.
