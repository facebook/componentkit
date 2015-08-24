Pod::Spec.new do |s|
  s.name             = "ComponentKitTestLib"
  s.version          = "0.13"
  s.summary          = "A React-inspired view framework for iOS"
  s.homepage         = "https://componentkit.org"
  s.license          = 'BSD'
  s.source           = { :git => "https://github.com/facebook/ComponentKit.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = '**/*.h', '**/*.m', '**/*.mm'
end
