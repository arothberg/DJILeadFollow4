//
//  MapViewController.swift
//  DJILeadFollow4
//
//  Created by Adam Rothberg on 1/20/18.
//  Copyright © 2018 Adam Rothberg. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet var mapView: MKMapView!
    
    let regionRadius: CLLocationDistance = 200
    let locationManager = CLLocationManager()
    var aircraftAnnotation : DJIAircraftAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Ask for Authorisation from the User.
        // self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }

        // Do any additional setup after loading the view.
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.locationManager.startUpdatingLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.locationManager.stopUpdatingLocation()
    }
    
    func updateAircraft(location : CLLocationCoordinate2D, withMapView : MKMapView) {
        if (aircraftAnnotation == nil) {
            aircraftAnnotation = DJIAircraftAnnotation(coordinate: location)
            withMapView.addAnnotation(aircraftAnnotation!)
        }
        aircraftAnnotation!.coordinate = location
    }
    
    func updateAircraft(heading : Float) {
        aircraftAnnotation?.updateHeading(heading: heading)
    }

    func cleanAllPoints(withMapView : MKMapView) {
        let annotations = withMapView.annotations
        annotations.forEach { (annotation) in
            if !annotation.isEqual(self.aircraftAnnotation) {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    func centerMap(location: CLLocation)
    {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locValue = manager.location?.coordinate {
            //print("locations = \(locValue.latitude) \(locValue.longitude)")
            centerMap(location: CLLocation(latitude: locValue.latitude, longitude: locValue.longitude))
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
