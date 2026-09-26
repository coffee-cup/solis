import Foundation
import CryptoKit
struct Fixture: Decodable {
 let id: String, latitude: Double, longitude: Double, start: Double, end: Double
 struct Event: Decodable { let altitude: Double, direction: Int, timestamp: Double }
 struct State: Decodable { let altitude: Double, above: Bool, below: Bool }
 let events: [Event], states: [State]
}
@main struct Verify {
 static func main() throws {
  let root = URL(fileURLWithPath: CommandLine.arguments[1])
  func data(_ file: String) throws -> Data { try Data(contentsOf: root.appendingPathComponent(file)) }
  let manifest = try JSONDecoder().decode([String:String].self,from:data("manifest.json"))
  for (file,expected) in manifest {
   let actual = SHA256.hash(data:try data(file)).map { String(format:"%02x",$0) }.joined()
   guard actual == expected else { fatalError("Changed reference fixture: \(file)") }
  }
  let original = try JSONDecoder().decode([Fixture].self,from:data("astronomy.json"))
  let adjudicated = try JSONDecoder().decode([Fixture].self,from:data("adjudicated.json"))
  let overrides = Dictionary(uniqueKeysWithValues:adjudicated.map { ($0.id,$0) })
  let rows = original.map { overrides[$0.id] ?? $0 }
  var failures = 0, worst = 0.0, total = 0
  let start = Date()
  for f in rows {
   let day = try SolarCalculator.calculate(interval: DateInterval(start: Date(timeIntervalSince1970:f.start), end:Date(timeIntervalSince1970:f.end)), latitude:f.latitude, longitude:f.longitude)
   if day.events.count != f.events.count { print("COUNT",f.id,day.events.count,f.events.count); failures += 1; continue }
   for (actual,expected) in zip(day.events,f.events) {
    let delta = abs(actual.date.timeIntervalSince1970-expected.timestamp)
    worst = max(worst,delta); total += 1
    if actual.threshold.rawValue != expected.altitude || actual.direction.rawValue != expected.direction || delta > 60 {
     print("EVENT",f.id,expected.altitude,expected.direction,delta); failures += 1
    }
   }
   for s in f.states {
    let state = day.state(at:SolarThreshold(rawValue:s.altitude)!)
    if (state == .above) != s.above || (state == .below) != s.below {print("STATE",f.id,s.altitude);failures += 1}
   }
  }
  print("RESULT cases=\(rows.count) events=\(total) failures=\(failures) worstSeconds=\(worst) elapsed=\(Date().timeIntervalSince(start))")
  if failures > 0 { exit(1) }
 }
}
