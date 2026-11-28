import MapKit
import Foundation

extension AppModel {
    func cancelRoute() {
        routeTask?.cancel()
        routeTask = nil
        routeRunning = false
        routePaused = false
        activeRouteLine = nil
        routeSpeed = 0
    }

    func beginRoute(to destination: SelectedCoordinate, walking: Bool, speed: Double, testVariation: Double = 0, previewedRoute: MKRoute? = nil) {
        guard let origin = simulatedCoordinate, !routeRunning, speed > 0,
              !isChangingSimulation, !areLocationWritesPausedForCellularHandoff else {
            presentError(title: "Cannot start route", message: "Check the starting location and connection readiness.")
            return
        }
        routeRunning = true
        routePaused = false
        routeProgress = 0
        routeStarted = Date()
        routeWalking = walking
        routeDistance = 0
        routeSpeed = 0
        activeRouteLine = nil
        routeTask = Task { [weak self] in
            guard let self else { return }
            defer { self.routeRunning = false; self.routePaused = false }
            do {
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coreLocationCoordinate))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coreLocationCoordinate))
                request.transportType = walking ? .walking : .automobile
                let resolvedRoute: MKRoute?
                if let previewedRoute { resolvedRoute = previewedRoute }
                else { resolvedRoute = try await MKDirections(request: request).calculate().routes.first }
                guard let route = resolvedRoute else {
                    self.presentError(title: "No route", message: "Choose a reachable destination.")
                    return
                }
                self.activeRouteLine = route.polyline
                self.routeDistance = route.distance
                let points = route.polyline.points()
                let count = route.polyline.pointCount
                guard count > 1 else { self.presentError(title: "No movement", message: "Choose a destination farther away."); return }
                let coordinates = (0..<count).map { points[$0].coordinate }
                var traveled = 0.0
                for index in 1..<count {
                    let a = coordinates[index-1], b = coordinates[index]
                    let distance = CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
                    let steps = max(1, Int(ceil(distance / (speed / 3.6 * 2))))
                    for step in 1...steps {
                        while self.routePaused { try await Task.sleep(for: .milliseconds(250)) }
                        let testSpeed = max(1, speed + Double.random(in: -max(0, testVariation)...max(0, testVariation)))
                        try await Task.sleep(for: .seconds(distance / Double(steps) / (testSpeed / 3.6)))
                        while self.routePaused { try await Task.sleep(for: .milliseconds(250)) }
                        try Task.checkCancellation()
                        while self.isChangingSimulation { try await Task.sleep(for: .milliseconds(250)) }
                        guard self.simulatedCoordinate != nil, !self.areLocationWritesPausedForCellularHandoff else {
                            self.presentError(title: "Route interrupted", message: "Location connection ended or writes are paused.")
                            return
                        }
                        let fraction = Double(step) / Double(steps)
                        let coordinate = SelectedCoordinate(latitude: a.latitude + (b.latitude-a.latitude)*fraction, longitude: a.longitude + (b.longitude-a.longitude)*fraction)
                        await self.updateRouteLocation(coordinate)
                        self.routeSpeed = testSpeed
                        guard self.simulatedCoordinate == coordinate else {
                            self.presentError(title: "Route interrupted", message: "Could not update the simulated location.")
                            return
                        }
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
