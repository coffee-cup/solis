# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
# Uncomment this line if you're using Swift
use_frameworks!

def swift3_overrides
    pod 'PermissionScope', git: 'https://github.com/nickoneill/PermissionScope.git', branch: 'swift3'
    pod 'SwiftyJSON', git: 'https://github.com/IBM-Swift/SwiftyJSON.git'
    pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git', branch: 'master'
end

def swift3_overrides_widget
end

target 'SunriseSunset' do
    inherit! :search_paths

    swift3_overrides

    pod 'EDSunriseSet', '~> 1.0'
    pod 'UIView-Easing'
    pod 'SwiftLocation'
    pod 'GoogleMaps'
    pod 'GooglePlaces'
    pod 'Fabric'
    pod 'Crashlytics'
end

target 'SolisWidget' do
    inherit! :search_paths

    swift3_overrides_widget

    pod 'EDSunriseSet', '~> 1.0'
    pod 'SwiftLocation'
end

target 'SunriseSunsetTests' do

end

target 'SunriseSunsetUITests' do

end

