Pod::Spec.new do |s|
  s.name = "ComponentKit"
  s.version = "0.12"
  s.summary = "A React-inspired view framework for iOS and OS X"
  s.homepage = "https://componentkit.org"
  s.authors = 'adamjernst@fb.com', 'andrewpouliot@fb.com', 'beefon@fb.com',
  s.license = 'BSD'
  s.source = {
    :git => "https://github.com/darknoon/ComponentKit-Mac.git",
    :tag => s.version.to_s
  }
  s.social_media_url = 'https://twitter.com/componentkit'
  s.ios.platform = :ios, '7.0'
  s.osx.platform = :osx, '10.10'
  s.osx.deployment_target = '10.10'
  s.requires_arc = true

  s.ios.source_files = 'ComponentKit/**/*', 'ComponentTextKit/**/*'
  #TODO: include the textkit bits as well
  s.osx.source_files = 'ComponentKit/**/*'
  s.osx.exclude_files = "ComponentKit/**/iOS/**/*"
  s.ios.exclude_files = "ComponentKit/**/OSX/**/*"

  s.ios.frameworks = 'UIKit', 'CoreText'
  s.osx.frameworks = 'AppKit', 'CoreText'
  s.library = 'c++'
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++',
  }
end
