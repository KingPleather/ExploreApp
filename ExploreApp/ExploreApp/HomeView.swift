//
//  HomeView.swift
//  ExploreApp
//
//  Created by Jono Tan on 3/1/26.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine


final class AppLocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var region: MKCoordinateRegion?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
}

extension AppLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        DispatchQueue.main.async {
            self.region = region
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}

struct HomeView: View {
    @StateObject private var locationManager = AppLocationManager()


    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var hasCenteredOnUser = false

    var body: some View {
        VStack {
            Spacer()

            Map(position: $position)
                .frame(width: 300, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(radius: 4)
                .onAppear {
                    locationManager.requestAuthorization()
                }
                .onReceive(locationManager.$region.compactMap { $0 }) { region in

                    if !hasCenteredOnUser {
                        withAnimation(.easeInOut) {
                            position = .region(region)
                        }
                        hasCenteredOnUser = true
                    }
                }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#Preview {
    HomeView()
}

