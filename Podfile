# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
# Uncomment this line if you're using Swift
use_frameworks!

def swift3_overrides
    pod 'PermissionScope', git: 'https://github.com/nickoneill/PermissionScope.git', branch: 'swift3'
    pod 'SwiftyJSON', git: 'https://github.com/IBM-Swift/SwiftyJSON.git'
    pod 'SwiftLocation', :git => 'https://github.com/malcommac/SwiftLocation.git', :commit => 'af2b78f3daf8e78c60537dd02103262676b53c3c'
    pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git', branch: 'master'
end

def swift3_overrides_widget
    pod 'SwiftLocation', :git => 'https://github.com/malcommac/SwiftLocation.git', :commit => 'af2b78f3daf8e78c60537dd02103262676b53c3c'
end

target 'SunriseSunset' do
    swift3_overrides

    pod 'EDSunriseSet', '~> 1.0'
    pod 'UIView-Easing'
    pod 'GoogleMaps'
    pod 'Fabric'
    pod 'Crashlytics'
end

target 'SolisWidget' do
    swift3_overrides_widget

    pod 'EDSunriseSet', '~> 1.0'
end

target 'SunriseSunsetTests' do

end

target 'SunriseSunsetUITests' do

end

