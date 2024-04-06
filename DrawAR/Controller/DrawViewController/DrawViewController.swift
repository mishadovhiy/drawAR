//
//  DrawViewController.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 05.04.2024.
//

import UIKit
import PencilKit
import SceneKit

class DrawViewController: UIViewController, PKToolPickerObserver {
    // MARK: - IBOutlet
    private var scrollView:UIScrollView? {
        view.subviews.first(where: {$0 is UIScrollView}) as? UIScrollView
    }
    var drawView:PKCanvasView? {
        scrollView?.subviews.first(where: {$0.layer.name == "pensilView"}) as? PKCanvasView
    }
    private var parentTabBar:TabBarController? { tabBarController as? TabBarController }
    
    // MARK: - properties
    public var positionHolder:SCNVector3?
    
    private var cameraPosition:SCNVector3? { parentTabBar?.cameraPosition}
    private var toolPicker:PKToolPicker?
    private let viewModel:DrawViewModel = .init()
    
    // MARK: - life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let zoomGestures = UIPinchGestureRecognizer(target: self, action: #selector(zoomGesture(_:)))
        view.addGestureRecognizer(zoomGestures)
        loadPencilKit()
        loadToolPicker()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        parentTabBar?.addTopButton(at: .right, button: loadSaveButton)
        parentTabBar?.addTopButton(at: .right, button: loadUploadButton)
        if let drawing = parentTabBar?.dataModelController.drawings[parentTabBar?.drawingIndex ?? 0] {
            drawView?.drawing = drawing
        }
    }
    
    // MARK: - public
    public var drawingImage:UIImage? {
        if #available(iOS 14.0, *) {
            if drawView?.drawing.strokes.count ?? 0 != 0 {
                return drawView?.drawing.image(from: drawView?.bounds ?? .zero, scale: 1.0)
            } else {
                return nil
            }
        } else {
            return drawView?.drawing.image(from: drawView?.bounds ?? .zero, scale: 1.0)
        }
    }
    
    private func drawTestNode() {
        let strokeSize: CGFloat = 40.0
        let pointLocation = CGPoint(
            x: 100,
            y: 100)
        if #available(iOS 14.0, *) {
            let point = PKStrokePoint(
                location: pointLocation,
                timeOffset: 0,
                size: CGSize(width: strokeSize, height: strokeSize),
                opacity: 1, force: 1, azimuth: 1, altitude: 1)
            let stroke = PKStroke(
                ink: PKInk(.pencil, color: .red),
                path: PKStrokePath(controlPoints: [point] ,
                                   creationDate: Date()))
            drawView?.drawing.strokes.append(stroke)
        }
    }
    
    @available(iOS 14.0, *)
    func convertNodeToPKStrokePoint(node: SCNNode, sceneView: SCNView, canvasView: PKCanvasView) -> PKStrokePoint? {
        guard let pointIn2D = convertNodeTo2DPoint(node: node, sceneView: sceneView) else {
            return nil
        }
        
        let convertedPoint = convertPointToCanvasCoordinates(pointIn2D, canvasView: canvasView)
        
        return PKStrokePoint(location: convertedPoint, timeOffset: .zero, size: .init(width: 200, height: 200), opacity: 1, force: 1, azimuth: 1, altitude: 1)
        ///PKStrokePoint(location: convertedPoint, timeOffset: 0)
    }

    func convertNodeTo2DPoint(node: SCNNode, sceneView: SCNView) -> CGPoint? {
        let nodePosition = node.worldPosition
        let pointIn3D = SCNVector3ToGLKVector3(nodePosition)
        let pointIn2D = sceneView.projectPoint(SCNVector3(x: pointIn3D.x, y: pointIn3D.y, z: pointIn3D.z))
        
        return CGPoint(x: CGFloat(pointIn2D.x), y: CGFloat(pointIn2D.y))
    }

    func convertPointToCanvasCoordinates(_ point: CGPoint, canvasView: PKCanvasView) -> CGPoint {
        return canvasView.convert(point, from: canvasView.superview)
    }
    
    // MARK: - IBAction
    @objc private func zoomGesture(_ sender: UIPinchGestureRecognizer) {
        performZoom(sender.scale, isEnded: sender.state.isEnded)
    }
    
    @objc private func uploadFromDevicePressed(_ sender:UIButton) {
        DispatchQueue(label: "db", qos: .userInitiated).async {
            let data = DB.db.drawedImage
            DispatchQueue.main.async {
                if let node = SCNNode.configure(data) {
                    if #available(iOS 14.0, *) {
                        if let draw = self.convertNodeToPKStrokePoint(node: node, sceneView: self.parentTabBar!.arVC!.sceneView, canvasView: self.drawView!) {
                            let stroke = PKStroke(
                                ink: PKInk(.pencil, color: .red),
                                path: PKStrokePath(controlPoints: [draw] ,
                                                   creationDate: Date()))
                            self.drawView?.drawing.strokes.append(stroke)
                        }
                    }
                }
            }
        }
    }
    
    @objc private func savePressed(_ sender:UIButton) { }
}

// MARK: - loadUI
fileprivate extension DrawViewController {
    func loadToolPicker() {
        if #available(iOS 14.0, *) {
            self.toolPicker = PKToolPicker()
            toolPicker?.setVisible(true, forFirstResponder: drawView!)
            toolPicker?.addObserver(drawView!)
            toolPicker?.addObserver(self)
            drawView?.becomeFirstResponder()
        }
    }
    
    func loadPencilKit() {
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(scrollView, at: 1)
        let drawView = PKCanvasView(frame: view.bounds)
        drawView.backgroundColor = .clear
        drawView.layer.name = "pensilView"
        if #available(iOS 14.0, *) {
            drawView.drawingPolicy = .anyInput
        }
        drawView.delegate = self
        scrollView.addSubview(drawView)
        scrollView.indicatorStyle = .white
        let drawSize:CGSize = .init(width: view.frame.width * 2.5, height: view.frame.height * 2.5)
        drawView.frame = .init(origin: .zero, size: drawSize)
        scrollView.addConstaits([.left:0, .right:0, .bottom:0, .top:0])
        drawViewFrameUpdated()
        scrollView.contentOffset = .init(x: scrollView.contentSize.width / 3, y: scrollView.contentSize.height / 3)
    }
    
    var loadSaveButton:UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(uploadFromDevicePressed(_:)), for: .touchUpInside)
        button.setTitle("Save", for: .normal)
        return button
    }
    
    var loadUploadButton:UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(uploadFromDevicePressed(_:)), for: .touchUpInside)
        button.setTitle("Add attachment", for: .normal)
        return button
    }
    
    // MARK: updateUI
    func drawViewFrameUpdated(contentOffcet:CGPoint? = nil) {
        scrollView?.contentSize = drawView?.frame.size ?? .zero - view.safeAreaInsets
    }
    
    func performZoom(_ newScale:CGFloat, isEnded:Bool) {
        let currentScale = drawView!.frame.size.width / drawView!.bounds.size.width
        let scale = viewModel.zoomScale(currentScale, newScale)
        
        drawView?.layer.zoom(value: scale)
        if drawView?.frame.origin != .zero {
            drawView?.frame.origin = .zero
        }
        if isEnded {
            drawViewFrameUpdated()
        }
    }
}

// MARK: - PKCanvasViewDelegate
extension DrawViewController: PKCanvasViewDelegate {
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        positionHolder = cameraPosition
        let material = SCNMaterial()
        material.diffuse.contents = drawingImage
        
        let plane = SCNPlane(width: 0.2, height: 0.2)
        plane.materials = [material]
        let drawingNode = SCNNode(geometry: plane)
        let data = drawingNode.data
        DispatchQueue.init(label: "db", qos: .userInitiated).async {
            DB.db.drawedImage = data
        }
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        parentTabBar?.nodeDrawed(drawingImage)
        drawViewFrameUpdated()
    }
}

// MARK: - configure
extension DrawViewController {
    static func configure() -> DrawViewController {
        let vc = UIStoryboard(name: "Draw", bundle: nil).instantiateViewController(withIdentifier: "DrawViewController") as! DrawViewController
        return vc
    }
}
