import ActivityKit
import Foundation

extension AppModel {
    func refreshSimulationActivity() {
        let enabled = UserDefaults.standard.object(forKey: "pinpointLiveActivity") as? Bool ?? true
        let active = simulatedCoordinate != nil && enabled && ActivityAuthorizationInfo().areActivitiesEnabled
        let state = PinpointSimulationAttributes.ContentState(status: areLocationWritesPausedForCellularHandoff ? "Location writes paused" : "Last location update confirmed", mode: routeRunning ? (routeWalking ? "Walking" : "Driving") : "Stationary", progress: routeProgress)
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(20))
        Task { @MainActor in
            let activities = Activity<PinpointSimulationAttributes>.activities
            if !active {
                for activity in activities { await activity.end(nil, dismissalPolicy: .immediate) }
            } else if let activity = activities.first {
                await activity.update(content)
            } else {
                do {
                    _ = try Activity.request(attributes: PinpointSimulationAttributes(started: .now), content: content, pushType: nil)
                } catch {
                    PinpointLog.shared.add("Live Activity unavailable", severity: "Error")
                }
            }
        }
    }
}
