#
# Be sure to run `pod lib lint Audiograph.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Audiograph'
  s.version          = '0.3.1'
  s.summary          = 'Audio-Feedback on Charts for visually impaired Users'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
iOS 13 introduced an awesome way to provide stocks-charts to visually impaired users.
Unfortunately there is no public API from Apple that enables developers to implement it in other apps (yet).

I think that charts can provide a great way of presenting information, but we should not limit their use to those without impairments.
This is where Audiograph comes into play.
                       DESC

  s.homepage         = 'https://github.com/Tantalum73/Audiograph'
  s.screenshots     = 'https://github.com/Tantalum73/Audiograph/raw/master/Media/Audiograph_preview.png'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Andreas Neusüß' => 'developer@anerma.de' }
  s.source           = { :git => 'https://github.com/Tantalum73/Audiograph.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Klaarname'

  s.ios.deployment_target = '10.3'
  s.swift_version = "5.1"

  s.source_files = 'Sources/Audiograph/*'

  # s.resource_bundles = {
  #   'Audiograph' => ['Audiograph/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'Foundation', 'AVFoundation'
  # s.dependency 'AFNetworking', '~> 2.3'
end
