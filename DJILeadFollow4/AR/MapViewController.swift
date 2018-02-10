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
    @IBAction func followBeacon(_ sender: UIButton) {
        DemoUtility.dbref.child("game/beacon").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if let longitude = snapshot.childSnapshot(forPath: "longitude").value as? Double, let latitude = snapshot.childSnapshot(forPath: "latitude").value as? Double
            {
                self?.beaconLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        })
    }
    
    @IBAction func dropBeacon(_ sender: UIButton) {
        let location = self.droneLocation
        if CLLocationCoordinate2DIsValid(location) {
            DemoUtility.dbref.child("game/beacon/longitude").setValue(location.longitude)
            DemoUtility.dbref.child("game/beacon/latitude").setValue(location.latitude)
            DemoUtility.dbref.child("game/beacon/altitude").setValue(self.droneAltitude)
        }
    }
    
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
    var beaconLocation : CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid {
        didSet {
        }
    }
    
    var droneLocation = kCLLocationCoordinate2DInvalid
    var droneAltitude : Double = 0.0
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
        updateStatusLabel(status: "Registering DJI...")
        DJISDKManager.registerApp(with: self)
    }
    
    func appRegisteredWithError(_ error: Error?) {
        if error != nil {
            let result = "Registration Error: \(error.debugDescription)"
            DemoUtility.showMessage(title: "DJI", message: result, view: self)
        } else {
            updateStatusLabel(status: "DJI Registered")
            //DemoUtility.showMessage(title: "DJI", message: "Registered!", view: self)
            DJISDKManager.startConnectionToProduct()
        }
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        if (product != nil) {
            let flightController = DemoUtility.fetchFlightController()
            flightController?.delegate = self
            updateStatusLabel(status: "Flight Controller obtained!")
        } else {
            DemoUtility.showMessage(title: "DJI", message: "Product Disconnected", view: self)
        }
    }
    
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        if let aircraftLocation = state.aircraftLocation {
            
            let mode = state.flightModeString
            let gps = state.satelliteCount
            let hs = sqrtf(state.velocityX*state.velocityX + state.velocityY*state.velocityY)
            let vs = state.velocityZ
            let altitude = state.altitude
            
            self.droneLocation = aircraftLocation.coordinate
            self.droneAltitude = altitude
            
            self.mapController?.updateAircraft(location: self.droneLocation, mapView: self.mapView)
            let radianYaw = state.attitude.yaw * Double.pi / 180
            self.mapController?.updateAircraft(heading: Float(radianYaw))
            
            let latitude = String.localizedStringWithFormat("%.5f", self.droneLocation.latitude)
            let longitude = String.localizedStringWithFormat("%.5f", self.droneLocation.longitude)
            let status = "Location: \(latitude):\(longitude)\nMode: \(mode) GPS: \(gps) HS: \(hs) m/s   VS: \(vs) m/s  Alt: \(altitude) m"
            updateStatusLabel(status: status)

            let kv : [String : Any] = [
                "latitude" : self.droneLocation.latitude,
                "longitude" : self.droneLocation.longitude,
                "mode" : mode,
                "gps" : gps,
                "vs" : vs,
                "hs" : hs,
                "altitude" : altitude
            ]
            kv.forEach({ (k, v) in
                DemoUtility.dbref.child("game/leader/\(k)").setValue(v)
            })
        }
    }
    
    private func updateStatusLabel (status : String) {
        DispatchQueue.main.async {
            print("Status Label: \(status)")
            self.labelStatus.text = status
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
