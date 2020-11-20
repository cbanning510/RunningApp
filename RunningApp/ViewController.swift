//
//  ViewController.swift
//  RunningApp
//
//  Created by chris on 11/20/20.
//

import UIKit
import MapKit
import MessageUI

class ViewController: UIViewController, MKMapViewDelegate, MFMessageComposeViewControllerDelegate, CustomUserLocDelegate {
    @IBOutlet weak var toggleDistanceTypeButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var beginEndRunButton: UIButton!
    
    var beginRunAnnotation: BeginRunSpot?
    var imageOfRoute: UIImage?
    var isMetric = false
    var isWorkoutCompleted = true
    var distanceInMiles = String()
    var distanceInMeters = String()
    var seconds = 0.0
    var distance = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationAuthStatus()
        mapView.delegate = self
        configureUI()
        self.mapView.showsUserLocation = true
    }
    
    func configureUI() {
        mapView.layer.cornerRadius = 8
        beginEndRunButton.layer.cornerRadius = 6
        toggleDistanceTypeButton.isHidden = true
        distanceLabel.isHidden = true
    }
    
    @IBAction func sendNewIMessage(_ sender: Any) {
        let messageVC = MFMessageComposeViewController()
        messageVC.body = "Check it out!"
        messageVC.recipients = ["3025551212"]
        messageVC.messageComposeDelegate = self
        let imageData = imageOfRoute!.jpegData(compressionQuality: 1.0)
        messageVC.addAttachmentData(imageData!, typeIdentifier: "image/jpg", filename: "photo.jpg")
        self.present(messageVC, animated: true, completion: nil)
    }
    
    @IBAction func convertButtonPressed(_ sender: UIButton) {
        if !isMetric {
            isMetric = true
            distanceLabel.text = "You've run \(distanceInMeters) kilometers!"
            toggleDistanceTypeButton.setTitle("convert to miles", for: .normal)
        } else {
            isMetric = false
            distanceLabel.text = "You've run \(distanceInMiles) miles!"
            toggleDistanceTypeButton.setTitle("convert to metric", for: .normal)
        }
    }
    
    @IBAction func startTracking(_ sender: Any) {
        if isWorkoutCompleted {
            isWorkoutCompleted = false
            LocationService.instance.arrayOfLocations.removeAll(keepingCapacity: false)
            LocationService.instance.locationManager.startUpdatingLocation()
            LocationService.instance.workoutHasStarted = true
            beginEndRunButton.setTitle("End Run", for: .normal)
            distanceLabel.isHidden = true
            toggleDistanceTypeButton.isHidden = true
            removeOverlays()
            seconds = 0.0
            distance = 0.0
            guard let coordinates = LocationService.instance.currentLocation else { return }
            setupAnnotation(coordinate: coordinates)
            centerMapOnUserLocation(coordinates: coordinates)
        } else {
            stopWorkout()
            isWorkoutCompleted = true
            LocationService.instance.workoutHasStarted = false
            beginEndRunButton.setTitle("Begin Run", for: .normal)
            toggleDistanceTypeButton.isHidden = false
            distanceLabel.isHidden = false
            LocationService.instance.currentLocation = nil
        }
    }
    
    func convertCLLocationCoordinate2DToCLLocation(Coord: CLLocationCoordinate2D) -> CLLocation {
        let lat: CLLocationDegrees = Coord.latitude
        let long: CLLocationDegrees = Coord.longitude
        let newCLLocation: CLLocation = CLLocation(latitude: lat, longitude: long)
        return newCLLocation
    }
    
    func calculateDistance() {
        let locations = LocationService.instance.arrayOfLocations
        if locations.count > 1 {
            for i in 0...locations.count - 2 {
                distance += locations[i + 1].distance(from: locations[i])
            }
        }
    }
    
    func stopWorkout() {
        let pinLocation: CLLocation = convertCLLocationCoordinate2DToCLLocation(Coord: beginRunAnnotation!.coordinate)
        LocationService.instance.arrayOfLocations.insert(pinLocation, at: 0)
        calculateDistance()
        distanceInMeters = String(format: "%.2f", distance/1000)
        distanceInMiles = String(format: "%.2f", distance/1609)
        distanceLabel.text = "You've run \(distanceInMiles) miles!"
        addPolylineToMap(locations: LocationService.instance.arrayOfLocations)
        imageOfRoute = self.mapView.takeScreenshot()
    }
    
    func addPolylineToMap(locations: [CLLocation]) {
        let coordinates = locations.map { $0.coordinate }
        let geodesic = MKGeodesicPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(geodesic)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let pathRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        pathRenderer.strokeColor = .blue
        pathRenderer.lineWidth = 5
        pathRenderer.alpha = 0.85
        
        return pathRenderer
    }
    
    func removeOverlays() {
        mapView.removeAnnotations(mapView.annotations)
        self.mapView.overlays.forEach { self.mapView.removeOverlay($0)}
    }
    
    func userLocationUpdated(location: CLLocation) {
        centerMapOnUserLocation(coordinates: location.coordinate)
    }
    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways ||  CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            LocationService.instance.customUserLocDelegate = self
        } else {
            LocationService.instance.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func centerMapOnUserLocation(coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 500, longitudinalMeters: 500)
        self.mapView.setRegion(region, animated: true)
    }
    
    func setupAnnotation(coordinate: CLLocationCoordinate2D) {
        beginRunAnnotation = BeginRunSpot(coordinate: coordinate)
        mapView.addAnnotation(beginRunAnnotation!)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? BeginRunSpot {
            let id = "pin"
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.canShowCallout = true
            view.animatesDrop = true
            view.pinTintColor = .red
            view.calloutOffset = CGPoint(x: -8, y: -3)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return view
        }
        return nil
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result) {
        case .cancelled:
            print("Message was cancelled")
        case .failed:
            print("Message failed")
        case .sent:
            print("Message was sent")
        default:
            return
        }
        controller.dismiss(animated: true, completion: nil)
    }
}

extension UIView {
    
    func takeScreenshot() -> UIImage {
        
        // Begin context
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        
        // Draw view in that context
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        
        // And finally, get image
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if (image != nil)
        {
            return image!
        }
        return UIImage()
    }
}


