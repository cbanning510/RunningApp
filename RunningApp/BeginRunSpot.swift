//
//  BeginRunSpot.swift
//  RunningApp
//
//  Created by chris on 11/20/20.
//

import UIKit
import MapKit

class BeginRunSpot: NSObject, MKAnnotation {
    var title: String? = "Run Started Here"
    var coordinate: CLLocationCoordinate2D
    var subtitle: String? = "Tap for Info"
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
