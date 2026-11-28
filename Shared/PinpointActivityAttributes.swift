import ActivityKit
import Foundation

struct PinpointActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: String
    }
    var started: Date
}

struct PinpointSimulationAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: String
        var mode: String
        var progress: Double
    }
    var started: Date
}
