//
//  ARViewController.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 05.04.2024.
//

import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController {
    //MARK: - IBOutlet
    @IBOutlet var sceneView: ARSCNView!
    private var parentTabBar:TabBarController? { tabBarController as? TabBarController }

    // MARK: - private properties
    private var drawingNode: SCNNode?
    private var positionHolder:SCNVector3? {
        parentTabBar?.positionHolder
    }

    // MARK: - life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(nodePositionChanged(_:))))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let drawedImage = parentTabBar?.drawingImage {
            nodeDrawed(drawedImage)
        }
        parentTabBar?.addTopButton(at: .right, button: loadReloadNodesButton)
    }
    
    // MARK: - public methods
    public func nodeDrawed(_ img:UIImage?) {
        if view == nil { return }
        let material = SCNMaterial()
        material.diffuse.contents = img
        if let existingNode = drawingNode, existingNode.parent != nil {
            existingNode.geometry?.firstMaterial = material
        } else {
            let plane = SCNPlane(width: 0.2, height: 0.2)
            plane.materials = [material]
            drawingNode = SCNNode(geometry: plane)
            print(self.positionHolder ?? .init(), " grrfeda")
            drawingNode?.position = .init(x: self.positionHolder?.x ?? 0, y: self.positionHolder?.y ?? 0, z: 0)//positionHolder.z
            sceneView.scene.rootNode.addChildNode(drawingNode!)
        }
    }
    
    public var cameraPosition:SCNVector3? {
        if view == nil { return nil }
        guard let pointOfView = sceneView.pointOfView else { return nil }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = SCNVector3(x: orientation.x + location.x, y: orientation.y + location.y, z: orientation.z + location.z)
        return currentPositionOfCamera
    }
    
    // MARK: - IBAction
    @objc private func nodePositionChanged(_ sender: UIPanGestureRecognizer) {
        let location = sender.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        if let result = hitResults.first {
            let node = result.node
            if sender.state == .changed {
                let translation = sender.translation(in: sceneView)
                let translationFactor: Float = 0.00002
                node.position.x += Float(translation.x) * translationFactor
                node.position.y -= Float(translation.y) * translationFactor
                sender.setTranslation(CGPoint.zero, in: sceneView)
            }
        }
    }
    
    @objc private func removeNodePressed(_ sender: UIButton) {
        parentTabBar?.positionHolder = cameraPosition
        drawingNode?.removeFromParentNode()
        if let drawedImage = parentTabBar?.drawingImage {
            nodeDrawed(drawedImage)
        }
    }
}

// MARK: - ARSCNViewDelegate
extension ARViewController: ARSCNViewDelegate, ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let currentTransform = frame.camera.transform
        let worldPosition = drawingNode?.worldPosition ?? .init()
        let screenPosition = sceneView.projectPoint(worldPosition)
    }
}

// MARK: - loadUI
fileprivate extension ARViewController {
    func loadARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    
    var loadReloadNodesButton: UIButton {
        let button = UIButton()
        button.setTitle("Reset position", for: .normal)
        button.addTarget(self, action: #selector(removeNodePressed(_:)), for: .touchUpInside)
        return button
    }
}

// MARK: - configure
extension ARViewController {
    static func configure() -> ARViewController {
        let vc = UIStoryboard(name: "AR", bundle: nil).instantiateViewController(withIdentifier: "ARViewController") as! ARViewController
        return vc
    }
}
