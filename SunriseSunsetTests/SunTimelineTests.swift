import CoreLocation
import Testing
import UIKit
@testable import SunriseSunset

struct SunTimelineTests {
    @Test func switchingFromPolarLocationRestoresEveryTimelineLine() {
        let view = UIView(frame:CGRect(x:0,y:0,width:400,height:7200))
        let gradient = CAGradientLayer()
        view.layer.addSublayer(gradient)
        let nowView = UIView()
        let timeLabel = UILabel(), nowLabel = UILabel()
        nowView.addSubview(timeLabel); nowView.addSubview(nowLabel)
        let sun = Sun(screenMinutes:360,screenHeight:800,sunHeight:7200,sunView:view,
                      gradientLayer:gradient,nowTimeLabel:timeLabel,nowLabel:nowLabel)
        let vancouver = CLLocationCoordinate2D(latitude:49.2827,longitude:-123.1207)
        sun.update(0,location:vancouver)
        let original = sun.sunTimeLines.map { $0.suntime.date }
        #expect(original.count >= 16)
        sun.update(0,location:CLLocationCoordinate2D(latitude:90,longitude:0))
        #expect(sun.sunTimeLines.count < original.count)
        sun.update(0,location:vancouver)
        #expect(sun.sunTimeLines.map { $0.suntime.date } == original)
        #expect(sun.sunTimeLines.allSatisfy { $0.sunline.superview === view })
        #expect(view.subviews.compactMap { $0 as? Sunline }.count == original.count)
        let layers = view.layer.sublayers!
        let backgroundIndex = layers.firstIndex { $0 === gradient }!
        for area in sun.sunAreas {
            let bandIndex = layers.firstIndex { $0 === area.layer }!
            #expect(bandIndex > backgroundIndex)
            #expect(sun.sunTimeLines.allSatisfy { line in layers.firstIndex { $0 === line.sunline.layer }! > bandIndex })
        }
        sun.toggleSunAreas()
        sun.toggleSunAreas()
        #expect(sun.sunAreas.allSatisfy { $0.topConstraint.constant.isFinite && $0.heightConstraint.constant >= 0 })
    }
}
