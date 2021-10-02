//
//  ViewController.swift
//  Elysium
//
//  Created by user on 28.09.21.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    @IBOutlet weak var metalView: MTKView!
    var renderer: TwoColorPhysarumRenderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let metalView = view as? MTKView else {
            fatalError("View isn't MTKView")
        }
        let size = CGSize(width: 1920, height: 1080)
        metalView.drawableSize = size
        renderer = TwoColorPhysarumRenderer(metalView: metalView)
    }


}

