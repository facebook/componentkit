Pod::Spec.new do |s|
  s.name = "ComponentKit"
  s.version = "0.9"
  s.summary = "A React-inspired view framework for iOS"
  s.homepage = "https://componentkit.com"
  s.authors = 'adamjernst@fb.com'
  s.license = 'BSD'
  s.source = {
    :git => "https://github.com/facebook/ComponentKit.git",
    :tag => s.version.to_s
  }
  s.social_media_url = 'https://twitter.com/componentkit'
  s.platform = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'ComponentKit/**/*', 'ComponentTextKit/**/*'
  s.frameworks = 'UIKit', 'CoreText'
  s.library = 'c++'
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'GCC_TREAT_WARNINGS_AS_ERRORS' => 'YES'
  }
end
