Pod::Spec.new do |s|
  s.name = 'ComponentTextKit'
  s.version = '0.30'
  s.license = 'BSD'
  s.summary = 'Base text library for ComponentKit'
  s.homepage = 'https://componentkit.org'
  s.authors = 'adamjernst@fb.com'
  s.source = { :git => 'https://github.com/facebook/ComponentKit.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.1'
  s.requires_arc = true

  s.source_files = 'ComponentTextKit/**/*.{h,m,mm}'
  s.frameworks = 'UIKit'
  s.library = 'c++'
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'gnu++14',
    'CLANG_CXX_LIBRARY' => 'libc++',
  }
end
