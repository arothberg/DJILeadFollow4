//
//  DJIMapController.swift
//  DJILeadFollow4
//
//  Created by Adam Rothberg on 1/21/18.
//  Copyright © 2018 Adam Rothberg. All rights reserved.
//

import Foundation
import MapKit

class DJIMapController : NSObject {
    
    private(set) var editPoints = NSMutableArray()
    var aircraftAnnotation : DJIAircraftAnnotation?

    override init() {
        super.init()
        self.editPoints = NSMutableArray()
    }
    
    func addPoint(point : CGPoint, mapView : MKMapView) {
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.editPoints.add(location)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
    }
    
    func cleanAllPoints(mapView : MKMapView) {
        let annotations = mapView.annotations
        annotations.forEach { (annotation) in
            if !annotation.isEqual(self.aircraftAnnotation) {
                mapView.removeAnnotation(annotation)
            }
        }
    }

    func updateAircraft(location : CLLocationCoordinate2D, mapView : MKMapView) {
        if (aircraftAnnotation == nil) {
            aircraftAnnotation = DJIAircraftAnnotation(coordinate: location)
            mapView.addAnnotation(aircraftAnnotation!)
        }
        aircraftAnnotation!.updateCoordinate(coordinate: location)
    }
    
    func updateAircraft(heading : Float) {
        aircraftAnnotation?.updateHeading(heading: heading)
    }
}
