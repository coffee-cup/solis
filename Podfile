# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
# Uncomment this line if you're using Swift
use_frameworks!

def swift3_overrides
end

def swift3_overrides_widget
end

target 'SunriseSunset' do
    inherit! :search_paths

    swift3_overrides

    pod 'Alamofire', '~> 4.5.1'
    pod 'PermissionScope'
    pod 'EDSunriseSet', '~> 1.0'
    pod 'UIView-Easing'
    pod 'SwiftLocation'
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

