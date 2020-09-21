Pod::Spec.new do |s|
  s.name = 'CKSwift'
  s.version = '0.30'
  s.license = 'BSD'
  s.summary = 'A Swift facade for ComponentKit'
  s.homepage = 'https://componentkit.org'
  s.social_media_url = 'https://twitter.com/componentkit'
  s.authors = 'adamjernst@fb.com'
  s.source = { :git => 'https://github.com/facebook/ComponentKit.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.1'
  s.requires_arc = true

  s.source_files = 'CKSwift/**/*'
  s.exclude_files = ['CKSwift/Info.plist']
  s.frameworks = 'UIKit'
  s.dependency 'ComponentKit', s.version.to_s
end
