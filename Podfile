# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'
# Uncomment this line if you're using Swift
use_frameworks!

def swift3_overrides
    pod 'PermissionScope', git: 'https://github.com/nickoneill/PermissionScope.git', branch: 'swift3'
    pod 'SwiftyJSON', git: 'https://github.com/SwiftyJSON/SwiftyJSON.git', branch: 'swift3'
end

def swift3_overrides_widget
end

target 'SunriseSunset' do
    swift3_overrides

    pod 'SwiftLocation'
    pod 'Alamofire'
    pod 'EDSunriseSet', '~> 1.0'
    pod 'UIView-Easing'
    pod 'GoogleMaps'
    pod 'Fabric'
    pod 'Crashlytics'
end

target 'SolisWidget' do
    swift3_overrides_widget

    pod 'SwiftLocation'
    pod 'EDSunriseSet', '~> 1.0'
end

target 'SunriseSunsetTests' do

end

target 'SunriseSunsetUITests' do

end

