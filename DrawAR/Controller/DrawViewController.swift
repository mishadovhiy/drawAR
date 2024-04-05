//
//  DrawViewController.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 05.04.2024.
//

import UIKit
import PencilKit
import SceneKit

class DrawViewController: UIViewController {
    // MARK: - IBOutlet
    private var scrollView:UIScrollView? {
        view.subviews.first(where: {$0 is UIScrollView}) as? UIScrollView
    }
    private var drawView:PKCanvasView? {
        scrollView?.subviews.first(where: {$0.layer.name == "pensilView"}) as? PKCanvasView
    }
    private var parentTabBar:TabBarController? { tabBarController as? TabBarController }
    
    // MARK: - public
    public var positionHolder:SCNVector3?
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
    // MARK: - private properties
    private var toolPicker:PKToolPicker?
    private var cameraPosition:SCNVector3? { parentTabBar?.cameraPosition}

    // MARK: - life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let zoomGestures = UIPinchGestureRecognizer(target: self, action: #selector(zoomGesture(_:)))
        view.addGestureRecognizer(zoomGestures)
        loadPencilKit()
        loadToolPicker()
    }

    // MARK: - IBAction
    @objc private func zoomGesture(_ sender: UIPinchGestureRecognizer) {
        performZoom(sender.scale, isEnded: sender.state.isEnded)
    }
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
    
    // MARK: updateUI
    func drawViewFrameUpdated(contentOffcet:CGPoint? = nil) {
        scrollView?.contentSize = drawView?.frame.size ?? .zero - view.safeAreaInsets
        if let contentOffcet,
            contentOffcet.x > 0,
            contentOffcet.y > 0,
            contentOffcet.x < scrollView?.contentSize.width ?? 0,
            contentOffcet.y > scrollView?.contentSize.height ?? 0 {
            scrollView?.contentOffset = contentOffcet
        }
    }
    
    func updateLayout(for toolPicker: PKToolPicker) {
        let obscuredFrame = toolPicker.frameObscured(in: view)
        if obscuredFrame.isNull {
            drawView?.contentInset = .zero
            navigationItem.leftBarButtonItems = []
        } else {
            drawView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.bounds.maxY - obscuredFrame.minY, right: 0)
        }
        drawView?.scrollIndicatorInsets = drawView!.contentInset
    }
    
    func performZoom(_ newScale:CGFloat, isEnded:Bool) {
        let currentScale = drawView!.frame.size.width / drawView!.bounds.size.width
        let senderScale = newScale
        var newScale = currentScale * senderScale
        if newScale <= 0.4 {
            newScale = 0.4
        } else if newScale >= 3 {
            newScale = 3
        }
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
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        parentTabBar?.nodeDrawed(drawingImage)
        drawViewFrameUpdated()
    }
}

// MARK: - PKToolPickerObserver
extension DrawViewController: PKToolPickerObserver {
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

// MARK: - configure
extension DrawViewController {
    static func configure() -> DrawViewController {
        let vc = UIStoryboard(name: "Draw", bundle: nil).instantiateViewController(withIdentifier: "DrawViewController") as! DrawViewController
        return vc
    }
}
