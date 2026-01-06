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
    @IBOutlet weak var drawOverScrollIndicatorView: UIView!
    @IBOutlet weak var drawOverScrollXIndocatorView: UIView!
    private var scrollView:UIScrollView? {
        view.subviews.first(where: {$0 is UIScrollView}) as? UIScrollView
    }
    var drawView:PKCanvasView? {
        scrollView?.subviews.first(where: {$0.layer.name == "pensilView"}) as? PKCanvasView
    }
    var backgroundImageView: UIImageView? {
        drawView?.subviews.first(where: {
            $0 is UIImageView
        }) as? UIImageView
    }
    private var parentTabBar:TabBarController? { tabBarController as? TabBarController }
    
    // MARK: - properties
    public var positionHolder:SCNVector3?
    
    private var cameraPosition:SCNVector3? { parentTabBar?.cameraPosition}
    private var toolPicker:PKToolPicker?
    private var viewModel:DrawViewModel = .init()
    private var backgroundImageParametersBarNavigation: UINavigationController? {
        children.first(where: {
            $0 is UINavigationController
        }) as? UINavigationController
    }
    // MARK: - life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let zoomGestures = UIPinchGestureRecognizer(target: self, action: #selector(zoomGesture(_:)))
        zoomGestures.name = "zoom"
        view.addGestureRecognizer(zoomGestures)
        drawOverScrollIndicatorView.translatesAutoresizingMaskIntoConstraints = true
        drawOverScrollXIndocatorView.translatesAutoresizingMaskIntoConstraints = true
        loadPencilKit()
        loadToolPicker()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        parentTabBar?.addTopButton(at: .right, button: loadDeleteButton, tintColor: .red)
        parentTabBar?.addTopButton(at: .right, button: loadShareButton)

        if let drawing = parentTabBar?.dataModelController.drawings[parentTabBar?.drawingIndex ?? 0], !viewModel.drawingSettedFromDB {
            drawView?.drawing = drawing
            viewModel.drawingSettedFromDB = true
            if UIDevice.current.userInterfaceIdiom == .phone {
                print("isIphonefsda")
                scrollView?.isScrollEnabled = false
            }
        }
        parentTabBar?.addTopButton(at: .left, button: loadToggleScrollButton)
        performToggleScroll(enuble: scrollView?.isScrollEnabled ?? true)
        didUpdateBackgroundImage()

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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let draw = drawView?.drawing.bounds ?? .zero
        let mainSize = UIApplication.shared.keyWindow?.bounds.size ?? .zero
        let scroll = scrollView.contentOffset
        let xHidden = calculateToggleScrollIndicator(drawRange: draw.minX...draw.maxX, scrollMin: scroll.x, scrollValue: mainSize.width)
        let yHidden = calculateToggleScrollIndicator(drawRange: draw.minY...draw.maxY, scrollMin: scroll.y, scrollValue: mainSize.height)
        drawOverScrollIndicatorView.isHidden = yHidden
        drawOverScrollXIndocatorView.isHidden = xHidden
        if draw.minY <= scroll.y {
            drawOverScrollIndicatorView.frame = .init(origin: .init(x: 0, y: 0), size: .init(width: mainSize.width, height: 4))
        } else {
            drawOverScrollIndicatorView.frame = .init(origin: .init(x: 0, y: mainSize.height - 4), size: .init(width: mainSize.width, height: 4))
        }
        if draw.minX >= scroll.x {
            drawOverScrollXIndocatorView.frame = .init(origin: .init(x: mainSize.width - 4, y: 0), size: .init(width: 4, height: mainSize.width))
        } else {
            drawOverScrollXIndocatorView.frame = .init(origin: .init(x: 0, y: 0), size: .init(width: 4, height: mainSize.width))
        }
    }
    
    func calculateToggleScrollIndicator(drawRange:ClosedRange<CGFloat>, scrollMin:CGFloat, scrollValue:CGFloat) -> Bool {
        let scrollMax = scrollValue + scrollMin
        let xScroll = scrollMin...scrollMax
        return drawRange.contains(xScroll.lowerBound) || drawRange.contains(scrollMax) || xScroll.contains(drawRange.lowerBound) || xScroll.contains(drawRange.upperBound)
    }
    
    // MARK: - IBAction
    @objc private func zoomGesture(_ sender: UIPinchGestureRecognizer) {
        performZoom(sender.scale, isEnded: sender.state.isEnded)
    }
    
    @objc private func uploadFromDevicePressed(_ sender:UIButton) {
    }
    
    @objc private func deletePressed(_ sender: UIButton) {
        drawView?.removeFromSuperview()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func sharePressed(_ sender: UIButton) {
        if #available(iOS 14.0, *) {
            let svgData = drawView?.convertDrawingToSVG
            let stringData = svgData?.data(using: .utf8)
            let paths = FileManager.default.temporaryDirectory
            let pdfURL = paths.appendingPathComponent("\(UUID().uuidString).svg")
            try? stringData?.write(to: pdfURL)
            let shareVC = self.shareVC(data: pdfURL) {
                let dataAtTemp = try? FileManager.default.contentsOfDirectory(atPath: paths.absoluteString)
                dataAtTemp?.forEach {
                    try? FileManager.default.removeItem(at: .init(string: $0)!)
                }
            }
            navigationController?.present(shareVC, animated: true)
        }
        
    }
    
    @objc private func savePressed(_ sender:UIButton) { }
    
    @objc private func toggleScrollEnubled(_ sender:UIButton) {
        let enuble = !(scrollView?.isScrollEnabled ?? false)
        performToggleScroll(enuble: enuble)
        sender.setTitle(enuble ? "Scroll enabled" : "Scroll disabled", for: .normal)
        AppDelegate.shared?.audioBox.vibrate(style: .default)
    }
    
    func toBackgroundOpacityEditor() {
        let vc = parametersVC(.init("Opacity", collectionData: [
            .slider(.init(value: Float(self.backgroundImageView?.alpha ?? 0), valueDidChange: { newValue in
                self.backgroundImageView?.alpha = CGFloat(newValue)
            }))
        ]))
        backgroundImageParametersBarNavigation?.pushViewController(vc, animated: true)
    }
    
    func didUpdateBackgroundImage() {
        let hasImage = backgroundImageView?.image != nil
        backgroundImageParametersBarNavigation?.popToRootViewController(animated: true)
        self.rootParatemersVC?.updateTableData(.init(
            "",
            collectionData: hasImage ? [
                .title(.init("delete", didSelect: {
                    self.backgroundImageView?.image = nil
                    self.didUpdateBackgroundImage()
                })),
                .title(.init("Opacity", didSelect: {
                    self.toBackgroundOpacityEditor()
                }))
            ] : [
                .title(.init("Select background", didSelect: {
                    
                }))
            ]))
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
        let drawSize:CGSize = .init(width: view.frame.width * 2.5, height: view.frame.height * 2.5)
        drawView.frame = .init(origin: .zero, size: drawSize)
        scrollView.addConstaits([.left:0, .right:0, .bottom:0, .top:0], safeArea: false)
        drawViewFrameUpdated()
        scrollView.contentOffset = .init(x: scrollView.contentSize.width / 3, y: scrollView.contentSize.height / 3)
        scrollView.delegate = self

        loadBackgroundImage()
        loadEditorParametersView()
    }
    
    func loadBackgroundImage() {
        let imageView = UIImageView()
        imageView.image = .test
        imageView.isUserInteractionEnabled = true
        drawView?.insertSubview(imageView, at: 0)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        imageView.centerXAnchor.constraint(equalTo: imageView.superview!.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: imageView.superview!.centerYAnchor).isActive = true

    }
    
    func loadEditorParametersView() {
        let editorView = UIStackView()
        scrollView?.addSubview(editorView)
        editorView.translatesAutoresizingMaskIntoConstraints = false
        editorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        editorView.topAnchor.constraint(greaterThanOrEqualTo: backgroundImageView!.topAnchor, constant: 50).isActive = true
        editorView.leadingAnchor.constraint(greaterThanOrEqualTo: backgroundImageView!.leadingAnchor, constant: 50).isActive = true
        editorView.topAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        editorView.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        
        editorView.addArrangedSubview(loadParametersChilderView)
        editorView.heightAnchor.constraint(equalToConstant: 100).isActive = true

        editorView.layer.zPosition = 999
    }
    
    func parametersVC(
        _ data: ParametersViewController.ScreenModel = .init()
    ) -> UIViewController {
        return ParametersViewController.configure(data)
    }
    
    var rootParatemersVC: ParametersViewController? {
        backgroundImageParametersBarNavigation?.viewControllers.first as? ParametersViewController
    }
    
    var loadParametersChilderView: UIView {
        let nav = UINavigationController(
            rootViewController: parametersVC()
        )
        addChild(nav)
        nav.didMove(toParent: self)
        nav.view.backgroundColor = .systemGray.withAlphaComponent(0.25)
        nav.view.layer.cornerRadius = 6
        nav.view.layer.masksToBounds = true
        return nav.view
    }
    
    var loadSaveButton:UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(uploadFromDevicePressed(_:)), for: .touchUpInside)
        button.setTitle("Save", for: .normal)
        return button
    }
    
    var loadToggleScrollButton:UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(toggleScrollEnubled(_:)), for: .touchUpInside)
        button.setTitle(scrollView?.isScrollEnabled ?? true ? "Scroll enabled" : "Scroll disabled", for: .normal)
        button.layer.name = "toggleScrollButton"
        return button
    }
    
    var loadDeleteButton:UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(deletePressed(_:)), for: .touchUpInside)
        button.setTitle("Delete", for: .normal)
        return button
    }
    
    var loadShareButton:UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(sharePressed(_:)), for: .touchUpInside)
        button.setTitle("Share", for: .normal)
        return button
    }
    
    var loadAttachmentButton:UIButton {
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
    
    private func performToggleScroll(enuble:Bool) {
        scrollView?.isScrollEnabled = enuble
        if #available(iOS 14.0, *) {
            drawView?.drawingPolicy = enuble ? .pencilOnly : .anyInput
        }
        let zoomGesture = view.gestureRecognizers?.first(where: {$0.name == "zoom"})
        zoomGesture?.isEnabled = enuble
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

// MARK: - configure
extension DrawViewController {
    static func configure() -> DrawViewController {
        let vc = UIStoryboard(name: "Draw", bundle: nil).instantiateViewController(withIdentifier: "DrawViewController") as! DrawViewController
        return vc
    }
}
