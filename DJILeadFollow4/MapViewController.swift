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
import DJISDK
import Firebase

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, DJISDKManagerDelegate, DJIFlightControllerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var editButton: UIButton!
    @IBOutlet var labelStatus: UILabel!
    
    @IBAction func refocusMap(_ sender: UIButton) {
        if (CLLocationCoordinate2DIsValid(self.droneLocation)) {
            let location = CLLocation(latitude: self.droneLocation.latitude, longitude: self.droneLocation.longitude)
            focusMap(location: location)
        }
        else if let userLocation = locationManager.location?.coordinate {
            let location = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            focusMap(location: location)
        }
    }
    
    @IBAction func editPoints(_ sender: UIButton) {
        if self.isEditingPoints {
            self.mapController?.cleanAllPoints(mapView: self.mapView)
            sender.setTitle("Edit", for: UIControlState.normal)
        }
        else {
            sender.setTitle("Reset", for: UIControlState.normal)
        }
        self.isEditingPoints = !self.isEditingPoints
    }
    
    let regionRadius: CLLocationDistance = 200
    let locationManager = CLLocationManager()
    var mapController : DJIMapController?
    var isEditingPoints = false
    
    var mode = "N/A"
    var gps = "0"
    var hs = "0.0 M/S"
    var vs = "0.0 M/S"
    var altitude = "0 M"
    
    var droneLocation = kCLLocationCoordinate2DInvalid
    var userLocation = kCLLocationCoordinate2DInvalid

    override func viewDidLoad() {
        super.viewDidLoad()

        // Ask for Authorisation from the User.
        // self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        // SDK
        registerApp()
        
        // map controller
        self.mapController = DJIMapController()
        
        // edit
        self.isEditingPoints = false
        editButton.setTitle("Edit", for: UIControlState.normal)
        
        //
        self.mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addWayPoints(tapGesture:))))
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 0.1
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
    
    func registerApp() {
        DJISDKManager.registerApp(with: self)
    }
    
    func appRegisteredWithError(_ error: Error?) {
        if error != nil {
            let result = "Registration Error: \(error.debugDescription)"
            DemoUtility.showMessage(title: "DJI", message: result, view: self)
        } else {
            DemoUtility.showMessage(title: "DJI", message: "Registered!", view: self)
            DJISDKManager.startConnectionToProduct()
        }
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        if (product != nil) {
            let flightController = DemoUtility.fetchFlightController()
            flightController?.delegate = self
            print("Flight Controller Worked!")
        } else {
            DemoUtility.showMessage(title: "DJI", message: "Product Disconnected", view: self)
        }
    }
    
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        if let aircraftLocation = state.aircraftLocation {
            self.droneLocation = aircraftLocation.coordinate
            self.mode = state.flightModeString
            self.gps = "\(state.satelliteCount)"
            self.vs = "\(state.velocityZ)"
            self.hs = "\(sqrtf(state.velocityX*state.velocityX + state.velocityY*state.velocityY))"
            self.altitude = "\(state.altitude)"
            
            self.mapController?.updateAircraft(location: self.droneLocation, mapView: self.mapView)
            let radianYaw = state.attitude.yaw * Double.pi / 180
            self.mapController?.updateAircraft(heading: Float(radianYaw))
            
            updateStatusLabel()

            let kv : [String : Any] = [
                "latitude" : self.droneLocation.latitude,
                "longitude" : self.droneLocation.longitude,
                "mode" : self.mode,
                "gps" : self.gps,
                "vs (m/s)" : self.vs,
                "hs (m/s)" : self.hs,
                "altitude" : self.altitude
            ]
            kv.forEach({ (k, v) in
                DemoUtility.dbref.child("leader/\(k)").setValue(v)
            })
        }
    }
    
    private func updateStatusLabel () {
        DispatchQueue.main.async {
            let latitude = String.localizedStringWithFormat("%.5f", self.droneLocation.latitude)
            let longitude = String.localizedStringWithFormat("%.5f", self.droneLocation.longitude)
            self.labelStatus.text = "Location: \(latitude):\(longitude)\nMode: \(self.mode)    GPS: \(self.gps)    HS: \(self.hs)   VS: \(self.vs)  Alt: \(self.altitude)"
        }
    }
    
    @objc func addWayPoints(tapGesture : UITapGestureRecognizer) {
        let point = tapGesture.location(in: self.mapView)
        if (tapGesture.state == UIGestureRecognizerState.ended) {
            if (self.isEditingPoints) {
                self.mapController?.addPoint(point: point, mapView: self.mapView)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: DJIAircraftAnnotation.self) {
            let annoView = DJIAircraftAnnotationView(annotation: annotation, reuseIdentifier: "Aircraft_Annotation")
            (annotation as! DJIAircraftAnnotation).annotationView = annoView
            return annoView
        } else if annotation.isKind(of: MKPointAnnotation.self) {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin_Annotation")
            pinView.pinTintColor = UIColor.purple
            return pinView
        }
        
        return nil
    }
    
    func focusMap(location: CLLocation)
    {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let locValue = manager.location?.coordinate {
//            //print("locations = \(locValue.latitude) \(locValue.longitude)")
//            focusMap(location: CLLocation(latitude: locValue.latitude, longitude: locValue.longitude))
//        }
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
