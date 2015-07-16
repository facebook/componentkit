Pod::Spec.new do |s|
  s.name             = "ComponentKitTestLib"
  s.version          = "0.1.0"
  s.summary          = "A React-inspired view framework for iOS"
  s.homepage         = "https://componentkit.com"
  s.license          = 'BSD'
  s.source           = { :git => "https://github.com/facebook/ComponentKit.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = '**/*.h', '**/*.m', '**/*.mm'
  s.dependency 'FBSnapshotTestCase'
  s.frameworks = 'UIKit', 'XCTest'
end
