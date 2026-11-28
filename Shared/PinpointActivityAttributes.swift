import ActivityKit
import Foundation

struct PinpointActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: String
    }
    var started: Date
}
