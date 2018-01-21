//
//  DJIAircraftAnnotationView.swift
//  DJILeadFollow4
//
//  Created by Adam Rothberg on 1/20/18.
//  Copyright © 2018 Adam Rothberg. All rights reserved.
//

import Foundation
import MapKit

class DJIAircraftAnnotationView : MKAnnotationView {
    
    init(annotation : MKAnnotation, reuseIdentifier : String) {
        super.init(annotation : annotation, reuseIdentifier : reuseIdentifier)
        self.isEnabled = false
        self.isDraggable = false
        self.image = #imageLiteral(resourceName: "aircraft")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateHeading(heading : Float) {
        self.transform = CGAffineTransform.identity
        self.transform = CGAffineTransform(rotationAngle: CGFloat(heading))
    }
}
