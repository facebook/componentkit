Pod::Spec.new do |s|
  s.name             = "ComponentSnapshotTestCase"
  s.version          = "0.13"
  s.summary          = "Support for Components with FBSnapshotTestCase"
  s.homepage         = "https://componentkit.org"
  s.license          = 'BSD'
  s.source           = { :git => "https://github.com/facebook/ComponentKit.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = '**/*.h', '**/*.m', '**/*.mm'
  s.dependency 'FBSnapshotTestCase/Core', '~> 2.0.4'
  s.frameworks = 'UIKit', 'XCTest'
end
