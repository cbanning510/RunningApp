//
//  LocationService.swift
//  RunningApp
//
//  Created by chris on 11/20/20.
//

import Foundation
import CoreLocation

protocol CustomUserLocDelegate {
    func userLocationUpdated(location: CLLocation)
}

class LocationService: NSObject, CLLocationManagerDelegate {
    static let instance = LocationService()
    
   
    var arrayOfLocations = [CLLocation]()
    var currentLocation: CLLocationCoordinate2D?
    var customUserLocDelegate: CustomUserLocDelegate?
    var locationManager = CLLocationManager()
    var workoutHasStarted = false
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = manager.location?.coordinate
        if customUserLocDelegate != nil {
            customUserLocDelegate?.userLocationUpdated(location: locations.first!)
        }
        if workoutHasStarted {
            arrayOfLocations.append(locations.last!)
        }
    }
}
