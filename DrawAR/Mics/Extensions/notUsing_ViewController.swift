import UIKit
import PencilKit
import ARKit
// MARK: -      !! SEGMENTED MOVE TO TABBARCONTROLLER
class ViewController: UIViewController {
    
    @IBOutlet private weak var settingsLabel: UILabel!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var settingsStackView: UIStackView!
    @IBOutlet private var sceneView: ARSCNView!
    private var scrollView:UIScrollView? {
        return view.subviews.first(where: {$0 is UIScrollView}) as? UIScrollView
    }
    private var drawView:PKCanvasView? {
        return scrollView?.subviews.first(where: {$0.layer.name == "pensilView"}) as? PKCanvasView
    }
    
    
    private var toolPicker:PKToolPicker?
    private var drawingNode: SCNNode?
    var positionHolder:SCNVector3?
    private let toggleSettingsAnimation = UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut)
    private var objectPositionGesture:UIPanGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        let scene = SCNScene()
        sceneView.scene = scene
        settingsStackView.superview?.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(toggleSettingsGesture(_:))))
        toggleSettigsView(show: false, animated: false)
        objectPositionGesture = .init(target: self, action: #selector(objectPositionChanged(_:)))
        sceneView.addGestureRecognizer(objectPositionGesture!)
        objectPositionGesture?.isEnabled = false
        
        let zoomGestures = UIPinchGestureRecognizer(target: self, action: #selector(zoomGesture(_:)))
        view.addGestureRecognizer(zoomGestures)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureARSession()
        configurePencilKit()
        configureToolPicker()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        segmentedChanged(segmentedControl)
    }
    
    // MARK: - @IBAction
    @IBAction func addNewDrawingPressed(_ sender: Any) {
        
    }
    
    @IBAction private func segmentedChanged(_ sender: UISegmentedControl) {
        let selected = sender.selectedSegmentIndex
        drawView?.isUserInteractionEnabled = selected == 0 || selected == 2
        objectPositionGesture?.isEnabled = selected == 1
        scrollView?.isHidden = selected != 2
    }
    
    @objc private func toggleSettingsGesture(_ sender:UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let currentY = settingsStackView.layer.frame.minY
        settingsStackView.layer.move(.top, value: translation.y + currentY)
        sender.setTranslation(.zero, in: view)
        switch sender.state {
        case .ended, .cancelled, .failed:
            let firstFrame = settingsStackView.subviews.first?.frame.height ?? 0
            self.toggleSettigsView(show: !(currentY <= firstFrame / -2))
        case .began:
            toggleSettingsAnimation.stopAnimation(true)
        default:
            break
        }
    }
    
    @objc private func objectPositionChanged(_ sender: UIPanGestureRecognizer) {
        
        let location = sender.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        
        if let result = hitResults.first {
            let node = result.node
            
            if sender.state == .changed {
                let translation = sender.translation(in: sceneView)
                let translationFactor: Float = 0.001
                
                node.position.x += Float(translation.x) * translationFactor
                node.position.y -= Float(translation.y) * translationFactor
                
                sender.setTranslation(CGPoint.zero, in: sceneView)
            }
        }
    }
        
    var zoom:CGFloat = 1
    @objc private func zoomGesture(_ sender: UIPinchGestureRecognizer) {
        let location = sender.location(in: view)
        let currentScale = drawView!.frame.size.width / drawView!.bounds.size.width
        let senderScale = sender.scale
        print(senderScale, " rtegfrwedasx")
        var newScale = currentScale * senderScale
        if newScale <= 0.1 {
            newScale = 0.1
        } else if newScale >= 3 {
            newScale = 3
        }
        zoom = newScale
        print(newScale, " rgtfedfwe from:", senderScale)
        drawView?.layer.zoom(value: newScale)
        print(drawView?.frame, " jyjuthyrgbvfc")
        let frameHolder = drawView?.frame
        if sender.state.isEnded {
            let drawingIsBigger = drawView?.frame.size ?? .zero >= view.frame.size
            let size = drawingIsBigger ? drawView?.frame.size ?? .zero : view.frame.size
            drawView?.frame = .init(origin: .zero, size: .init(width: size.width, height: size.height))
            drawViewFrameUpdated()
        }
    }
}

// MARK: - confugure
fileprivate extension ViewController {
    func configureARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    func configureToolPicker() {
        if #available(iOS 14.0, *) {
            self.toolPicker = PKToolPicker()
            toolPicker?.setVisible(true, forFirstResponder: drawView!)
            toolPicker?.addObserver(drawView!)
            toolPicker?.addObserver(self)
            drawView?.becomeFirstResponder()
        }
    }
    
    func configurePencilKit() {
        let scrollView = UIScrollView(frame: view.bounds)
                scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(scrollView, at: 1)
        
        let drawView = PKCanvasView(frame: view.bounds)
        drawView.backgroundColor = .clear
        drawView.layer.name = "pensilView"
        
        if #available(iOS 14.0, *) {
            drawView.drawingPolicy = .anyInput
        } else {
        }
        drawView.delegate = self
        scrollView.addSubview(drawView)
        //view.insertSubview(drawView, at: 1)
        drawView.backgroundColor = .black
        drawView.frame = view.frame
        scrollView.addConstaits([.left:0, .right:0, .bottom:0, .top:0])
        drawViewFrameUpdated()
    }
}

//MARK: - setUI
fileprivate extension ViewController {
    final func toggleSettigsView(show:Bool, animated:Bool = true) {
        toggleSettingsAnimation.stopAnimation(true)
        if animated {
            toggleSettingsAnimation.addAnimations {
                self.performToggleSettingsView(show: show)
            }
            toggleSettingsAnimation.startAnimation()
        } else {
            performToggleSettingsView(show: show)
        }
    }
    
    func performToggleSettingsView(show:Bool) {
        let firstFrame = settingsStackView.subviews.first?.frame.height ?? 0
        self.settingsStackView.layer.move(.top, value: !show ? firstFrame / -1 : 0)
    }
    
    func updateLayout(for toolPicker: PKToolPicker) {
        let obscuredFrame = toolPicker.frameObscured(in: view)
        if obscuredFrame.isNull {
            drawView?.contentInset = .zero
            navigationItem.leftBarButtonItems = []
        }
        
        else {
            drawView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.bounds.maxY - obscuredFrame.minY, right: 0)
        }
        drawView?.scrollIndicatorInsets = drawView!.contentInset
    }
    
    private func drawViewFrameUpdated(contentOffcet:CGPoint? = nil) {
        scrollView?.contentSize = drawView?.frame.size ?? .zero - view.safeAreaInsets
        scrollView?.contentOffset = contentOffcet ?? .zero
    }
}


extension ViewController: PKToolPickerObserver {
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        drawView?.tool = toolPicker.selectedTool
        print(toolPicker)
    }
    
    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }
    
    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }
}


extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
    //    print(node.geometry, " gbevwds")
        // Use the geometry as needed...
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
    }
    
    private var cameraPosition:SCNVector3? {
        guard let pointOfView = sceneView.pointOfView else { return nil }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = SCNVector3(x: orientation.x + location.x, y: orientation.y + location.y, z: orientation.z + location.z)
        return currentPositionOfCamera
    }
}


extension ViewController: PKCanvasViewDelegate {
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        //if nil - start camera
        positionHolder = cameraPosition
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        print(sceneView.overlaySKScene?.position, " refdasz")
        let drawingImage = canvasView.drawing.image(from: canvasView.bounds, scale: 1.0)
        if #available(iOS 14.0, *) {
            print(canvasView.drawing.strokes.count, " rthegrfdas")
        } else {
        }
        print(canvasView.drawing.bounds, " jutyhrgf")

        let material = SCNMaterial()
        material.diffuse.contents = drawingImage
        if let existingNode = drawingNode {
            existingNode.geometry?.firstMaterial = material
        } else {
            let plane = SCNPlane(width: 0.2, height: 0.2)
            
            plane.materials = [material]
            drawingNode = SCNNode(geometry: plane)
            print(self.positionHolder, " grrfeda")
            drawingNode?.position = .init(x: self.positionHolder?.x ?? 0, y: self.positionHolder?.y ?? 0, z: 0)//positionHolder.z
            sceneView.scene.rootNode.addChildNode(drawingNode!)
        }
        drawViewFrameUpdated()
    }
}
