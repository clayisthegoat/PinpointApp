import MapKit
import Foundation

extension AppModel {
    func cancelRoute() {
        routeTask?.cancel()
        routeTask = nil
        routeRunning = false
    }

    func beginRoute(to destination: SelectedCoordinate, walking: Bool, speed: Double) {
        guard let origin = simulatedCoordinate, !routeRunning, speed > 0,
              !isChangingSimulation, !areLocationWritesPausedForCellularHandoff else { return }
        routeRunning = true
        routeProgress = 0
        routeTask = Task { [weak self] in
            guard let self else { return }
            defer { self.routeRunning = false }
            do {
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coreLocationCoordinate))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coreLocationCoordinate))
                request.transportType = walking ? .walking : .automobile
                let response = try await MKDirections(request: request).calculate()
                guard let route = response.routes.first else {
                    self.presentError(title: "No route", message: "Choose a reachable destination.")
                    return
                }
                let points = route.polyline.points()
                let count = route.polyline.pointCount
                guard count > 1 else { return }
                let coordinates = (0..<count).map { points[$0].coordinate }
                var traveled = 0.0
                for index in 1..<count {
                    let a = coordinates[index-1], b = coordinates[index]
                    let distance = CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
                    let steps = max(1, Int(ceil(distance / (speed / 3.6 * 2))))
                    for step in 1...steps {
                        try await Task.sleep(for: .seconds(distance / Double(steps) / (speed / 3.6)))
                        guard !Task.isCancelled, self.simulatedCoordinate != nil,
                              !self.areLocationWritesPausedForCellularHandoff, !self.isChangingSimulation else { return }
                        let fraction = Double(step) / Double(steps)
                        let coordinate = SelectedCoordinate(latitude: a.latitude + (b.latitude-a.latitude)*fraction, longitude: a.longitude + (b.longitude-a.longitude)*fraction)
                        await self.startSimulation(at: coordinate)
                        guard self.simulatedCoordinate == coordinate else { return }
                        self.routeProgress = min(1, (traveled + distance*fraction) / max(route.distance, 1))
                    }
                    traveled += distance
                }
                self.routeProgress = 1
            } catch {
                if !Task.isCancelled { self.presentError(title: "Route interrupted", error: error) }
            }
        }
    }

    func cancelRestoreTimer() {
        restoreTask?.cancel()
        restoreTask = nil
        restoreDeadline = nil
    }

    func scheduleRestore(minutes: Int) {
        guard simulatedCoordinate != nil, minutes > 0 else { return }
        cancelRestoreTimer()
        restoreDeadline = Date().addingTimeInterval(Double(minutes * 60))
        restoreTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(minutes * 60))
                guard let self, !Task.isCancelled else { return }
                self.cancelRoute()
                while self.isChangingSimulation || self.isCellularLaunchRunning {
                    try await Task.sleep(for: .seconds(1))
                }
                self.restoreDeadline = nil
                if self.simulatedCoordinate != nil { await self.stopSimulation() }
            } catch {}
        }
    }
}
