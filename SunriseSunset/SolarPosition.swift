import Foundation

/// NREL SPA apparent solar position, with sea-level topocentric parallax.
/// No atmospheric refraction: event thresholds already encode that convention.
nonisolated enum SolarPosition {
    private static let radians = Double.pi / 180

    static func altitude(at date: Date, latitude: Double, longitude: Double) -> Double {
        let jd = date.timeIntervalSince1970 / 86400 + 2440587.5
        let jc = (jd - 2451545) / 36525
        let t = (jd + deltaT(at: date) / 86400 - 2451545) / 36525
        let m = t / 10
        func series(_ rows: [[Double]]) -> Double {
            rows.reduce(0) { $0 + $1[0] * cos($1[1] + $1[2] * m) }
        }
        func polynomial(_ coefficients: [Double], _ x: Double) -> Double {
            coefficients.reversed().reduce(0) { $0 * x + $1 }
        }
        let c = SolarCoefficients.self
        let longitudeEarth = polynomial([series(c.L0), series(c.L1), series(c.L2), series(c.L3), series(c.L4), series(c.L5)], m) / 1e8
        let beta = -polynomial([series(c.B0), series(c.B1)], m) / 1e8
        let radius = polynomial([series(c.R0), series(c.R1), series(c.R2), series(c.R3), series(c.R4)], m) / 1e8
        let arguments = [
            polynomial([297.85036,445267.111480,-0.0019142,1/189474.0],t),
            polynomial([357.52772,35999.050340,-0.0001603,-1/300000.0],t),
            polynomial([134.96298,477198.867398,0.0086972,1/56250.0],t),
            polynomial([93.27191,483202.017538,-0.0036825,1/327270.0],t),
            polynomial([125.04452,-1934.136261,0.0020708,1/450000.0],t)
        ]
        var psi = 0.0, epsilonCorrection = 0.0
        for (terms, coefficients) in zip(c.NUTATION_YTERM_ARRAY, c.NUTATION_ABCD_ARRAY) {
            let angle = zip(terms, arguments).reduce(0) { $0 + $1.0 * $1.1 } * radians
            psi += (coefficients[0] + coefficients[1] * t) * sin(angle)
            epsilonCorrection += (coefficients[2] + coefficients[3] * t) * cos(angle)
        }
        psi /= 36_000_000
        epsilonCorrection /= 36_000_000
        let epsilon = (polynomial([84381.448,-4680.93,-1.55,1999.25,-51.38,-249.67,-39.05,7.12,27.87,5.79,2.45],m/10)/3600 + epsilonCorrection) * radians
        let lambda = longitudeEarth + .pi + (psi - 20.4898/(3600*radius)) * radians
        let ascension = atan2(sin(lambda)*cos(epsilon)-tan(beta)*sin(epsilon),cos(lambda))
        let declination = asin(sin(beta)*cos(epsilon)+cos(beta)*sin(epsilon)*sin(lambda))
        let sidereal = 280.46061837 + 360.98564736629*(jd-2451545) + 0.000387933*jc*jc - jc*jc*jc/38710000 + psi*cos(epsilon)
        let hourAngle = (sidereal + longitude) * radians - ascension
        let latitudeRadians = latitude * radians
        let u = atan(0.99664719*tan(latitudeRadians))
        let x = cos(u), y = 0.99664719*sin(u)
        let parallax = 8.794/(3600*radius)*radians
        let deltaAscension = atan2(-x*sin(parallax)*sin(hourAngle),cos(declination)-x*sin(parallax)*cos(hourAngle))
        let topocentricDeclination = atan2((sin(declination)-y*sin(parallax))*cos(deltaAscension),cos(declination)-x*sin(parallax)*cos(hourAngle))
        let h = hourAngle-deltaAscension
        let sine = sin(latitudeRadians)*sin(topocentricDeclination)+cos(latitudeRadians)*cos(topocentricDeclination)*cos(h)
        return asin(min(1,max(-1,sine))) / radians
    }

    /// Espenak/Meeus polynomial estimates, seconds TT minus UT.
    /// https://eclipse.gsfc.nasa.gov/SEcat5/deltatpoly.html
    static func deltaT(at date: Date) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = Double(components.year!) + (Double(components.month!)-0.5)/12
        func p(_ origin: Double, _ coefficients: [Double]) -> Double {
            coefficients.reversed().reduce(0) { $0 * (year-origin) + $1 }
        }
        switch year {
        case ..<1860: return p(1800,[13.72,-0.332447,0.0068612,0.0041116,-0.00037436,0.0000121272,-0.0000001699,0.000000000875])
        case ..<1900: return p(1860,[7.62,0.5737,-0.251754,0.01680668,-0.0004473624,1/233174.0])
        case ..<1920: return p(1900,[-2.79,1.494119,-0.0598939,0.0061966,-0.000197])
        case ..<1941: return p(1920,[21.20,0.84493,-0.076100,0.0020936])
        case ..<1961: return p(1950,[29.07,0.407,-1/233.0,1/2547.0])
        case ..<1986: return p(1975,[45.45,1.067,-1/260.0,-1/718.0])
        case ..<2005: return p(2000,[63.86,0.3345,-0.060374,0.0017275,0.000651814,0.00002373599])
        case ..<2050: return p(2000,[62.92,0.32217,0.005589])
        default: return -20 + 32*pow((year-1820)/100,2) - 0.5628*(2150-year)
        }
    }
}
