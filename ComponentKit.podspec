Pod::Spec.new do |s|
  s.name = 'ComponentKit'
  s.version = '0.15.1'
  s.license = 'BSD'
  s.summary = 'A React-inspired view framework for iOS'
  s.homepage = 'https://componentkit.org'
  s.social_media_url = 'https://twitter.com/componentkit'
  s.authors = 'adamjernst@fb.com'
  s.source = { :git => 'https://github.com/facebook/ComponentKit.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.1'
  s.tvos.deployment_target = '9.1'
  s.requires_arc = true
  s.source_files = 'ComponentKit/**/*', 'ComponentTextKit/**/*'
  s.frameworks = 'UIKit', 'CoreText'
  s.library = 'c++'
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++',
  }
end
