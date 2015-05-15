Pod::Spec.new do |s|
  s.name             = "ComponentKitTestLib"
  s.version          = "0.11"
  s.summary          = "A React-inspired view framework for iOS"
  s.homepage         = "https://componentkit.org"
  s.license          = 'BSD'
  s.source           = { :git => "https://github.com/facebook/ComponentKit.git", :tag => s.version.to_s }
  s.ios.platform     = :ios, '7.0'
  s.osx.platform     = :osx, '10.10'
  s.requires_arc = true
  s.source_files = '**/*.h', '**/*.m', '**/*.mm'
  s.ios.dependency 'FBSnapshotTestCase'
  s.frameworks = 'UIKit', 'XCTest'
end
