xcodeproj 'ComponentKit.xcodeproj'
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

pod 'ComponentKit', :path => '.'

target 'ComponentKitTests' do
	pod 'OCMock', '~> 3.2'
	pod 'ComponentKit/ComponentKitTestHelpers', :path => '.'
	pod 'ComponentKit/ComponentKitTestLib', :path => '.'
end

target 'ComponentKitApplicationTests' do
	pod 'ComponentKit/ComponentKitTestHelpers', :path => '.'
	pod 'ComponentKit/ComponentSnapshotTestCase', :path => '.'
end

target 'ComponentTextKitApplicationTests' do
	pod 'ComponentKit/ComponentSnapshotTestCase', :path => '.'
end