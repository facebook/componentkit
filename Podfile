xcodeproj 'ComponentKit.xcodeproj'
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

pod 'ComponentKit', :path => '.'

target 'ComponentKitTests' do
	pod 'OCMock', '~> 2.2'
	pod 'ComponentKit/ComponentKitTestLib', :path => '.'
end

target 'ComponentKitApplicationTests' do
	pod 'ComponentKit/ComponentSnapshotTestCase', :path => '.'
end

target 'ComponentTextKitApplicationTests' do
	pod 'ComponentKit/ComponentKitTestHelpers', :path => '.'
	pod 'ComponentKit/ComponentSnapshotTestCase', :path => '.'
end