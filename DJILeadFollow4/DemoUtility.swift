//
//  DemoUtility.swift
//  DJILeadFollow4
//
//  Created by Adam Rothberg on 1/21/18.
//  Copyright © 2018 Adam Rothberg. All rights reserved.
//

import Foundation
import DJISDK
import Firebase

class DemoUtility {
    
    static var dbref : DatabaseReference = {
        return Database.database().reference()
    }()

    class func showMessage(title : String, message : String, view : UIViewController) {
        DispatchQueue.main.async {
            print(message)
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(alertAction)
            alertController.show(view, sender: nil)
        }
    }
    
    class func fetchFlightController() -> DJIFlightController? {
        if let product = DJISDKManager.product() as? DJIAircraft {
            return product.flightController
        }
        return nil
    }
}
