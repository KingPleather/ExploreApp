//
//  LocationManager.swift
//  
//
//  Created by Cherry Ni on 3/1/26.
//

import CoreLocation
import MapKit

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var userLocation: CLLocation?
    var homeLocation: CLLocation?
    var distanceToHome: Double = 0
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        
        if let user = userLocation, let home = homeLocation {
            distanceToHome = user.distance(from: home)
        }
    }
    
    func setHome() {
        homeLocation = userLocation
    }
}
