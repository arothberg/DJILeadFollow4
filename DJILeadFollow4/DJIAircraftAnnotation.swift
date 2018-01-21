//
//  DJIAircraftAnnotation.swift
//  DJILeadFollow4
//
//  Created by Adam Rothberg on 1/21/18.
//  Copyright © 2018 Adam Rothberg. All rights reserved.
//

import Foundation
import MapKit

class DJIAircraftAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    weak var annotationView : DJIAircraftAnnotationView?
    
    init(coordinate : CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
    
    func updateHeading(heading : Float) {
        annotationView?.updateHeading(heading: heading)
    }
}
