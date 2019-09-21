#
# Be sure to run `pod lib lint CDNetworkReachability.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CDNetworkReachability'
  s.version          = '1.0.1'
  s.summary          = 'iOS网络变化检测.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
监测网络发生变化，检测是否网络授权
                       DESC

  s.homepage         = 'https://github.com/cqzhong/CDNetworkReachability'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cqzhong' => '2863802082@qq.com' }
  s.source           = { :git => 'https://github.com/cqzhong/CDNetworkReachability.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'CDNetworkReachability/**/*.{h,m}'

  # s.resource_bundles = {
  #   'CDNetworkReachability' => ['CDNetworkReachability/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
