//
//  DJIAircraftAnnotation.swift
//  DJILeadFollow4
//
//  Created by Adam Rothberg on 1/21/18.
//  Copyright © 2018 Adam Rothberg. All rights reserved.
//

import Foundation
import MapKit

class DJIAircraftAnnotation : MKPointAnnotation {

    weak var annotationView : DJIAircraftAnnotationView?
    
    init(coordinate : CLLocationCoordinate2D) {
        super.init()
        self.coordinate = coordinate
    }
    
    func updateHeading(heading : Float) {
        annotationView?.updateHeading(heading: heading)
    }
    
    func updateCoordinate(coordinate : CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
