//
//  SceneViewController.swift
//  DJILeadFollow4
//
//  Created by Adam Rothberg on 2/11/18.
//  Copyright © 2018 Adam Rothberg. All rights reserved.
//

import UIKit
import SceneKit

class SceneViewController: UIViewController {

    @IBOutlet var sceneView: SCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        sceneSetup()
    }
    
    func sceneSetup() {
        sceneView.allowsCameraControl = true
        
        let scene = SCNScene()
        //let boxGeometry = SCNBox(width: 10, height: 10, length: 10, chamferRadius: 1.0)
        //let boxNode = SCNNode(geometry: boxGeometry)
        let sphereGeo = SCNSphere(radius: 100)
        sphereGeo.firstMaterial?.transparency = 0.3
        let sphereNode = SCNNode(geometry: sphereGeo)
        
        let sphere2Geo = SCNSphere(radius: 30)
        let sphere2Node = SCNNode(geometry: sphere2Geo)
        
        scene.rootNode.addChildNode(sphereNode)
        sphereNode.addChildNode(sphere2Node)
        
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
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
