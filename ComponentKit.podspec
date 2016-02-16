Pod::Spec.new do |s|
  s.name = "ComponentKit"
  s.version = "0.13"
  s.summary = "A React-inspired view framework for iOS"
  s.homepage = "https://componentkit.org"
  s.authors = 'adamjernst@fb.com'
  s.license = 'BSD'
  s.source = {
    :git => "https://github.com/facebook/ComponentKit.git",
    :tag => s.version.to_s
  }
  s.social_media_url = 'https://twitter.com/componentkit'
  s.platform = :ios, '7.0'
  s.requires_arc = true

  s.library = 'c++'
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++',
  }

  #Subspecs

  s.subspec 'Core' do |cs|
    cs.source_files = [
      'ComponentKit/**/*', 
      'ComponentTextKit/**/*'
    ]
    cs.frameworks = 'UIKit', 'CoreText'

  end

  s.subspec 'ComponentKitTestHelpers' do |sts|
    sts.source_files = 'ComponentKitTestHelpers/*.{h, m, mm}'
    sts.dependency 'ComponentKit/Core'
  end

  s.subspec 'ComponentSnapshotTestCase' do |sts|
    sts.source_files = 'ComponentSnapshotTestCase/*.{h, m, mm}'
    sts.public_header_files = 'ComponentSnapshotTestCase/ComponentSnapshotTestCase.h'
    sts.dependency 'ComponentKit/Core'
    sts.dependency 'FBSnapshotTestCase/Core', '~> 2.0.4'
    sts.frameworks = 'XCTest'
  end

  s.subspec 'ComponentKitTestLib' do |tbs|
    tbs.source_files = 'ComponentKitTestLib/*.{h, m, mm}'  
    tbs.public_header_files = 'ComponentKitTestLib/CKComponentTestRootScope.h'
    tbs.dependency 'ComponentKit/Core'
  end
  
  s.default_subspec = 'Core'
end
