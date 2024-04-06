//
//  TabBarController.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 05.04.2024.
//

import UIKit
import SceneKit

class TabBarController: UITabBarController {
    // MARK: - IBOutlet
    private var arVC:ARViewController? {
        viewControllers?.first(where: {$0 is ARViewController}) as? ARViewController
    }
    private var drawVC:DrawViewController? {
        viewControllers?.first(where: {$0 is DrawViewController}) as? DrawViewController
    }
    private var settingsStackView:UIStackView? {
        let view = view.subviews.first(where: {$0.layer.name == "segmentSuperview"})
        return view?.subviews.first(where: {$0 is UIStackView}) as? UIStackView
    }
    private var segmentedControl:UISegmentedControl? {
        let view = settingsStackView?.arrangedSubviews.first(where: {$0.layer.name != "emptyView"})
        let stackView = view?.subviews.first as? UIStackView
        return stackView?.arrangedSubviews.first(where: {$0 is UISegmentedControl}) as? UISegmentedControl
    }
    private var contentStack: UIStackView? {
        segmentedControl?.superview as? UIStackView
    }
    
    // MARK: - properties
    public var cameraPosition:SCNVector3? {
        arVC?.cameraPosition
    }
    public var positionHolder:SCNVector3? {
        get {
            drawVC?.positionHolder
        }
        set {
            drawVC?.positionHolder = newValue
        }
    }
    public var drawingImage:UIImage? { drawVC?.drawingImage}
    var dataModelController: DataModelController!
    var drawingIndex:Int!
    private let toggleSettingsAnimation = UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut)
    
    // MARK: - life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        RequestAccess.camera()
        viewControllers = [
            DrawViewController.configure(),
            ARViewController.configure()
        ]
        loadSegmentControl()
        loadOptionsStack()
        tabBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveDrawingToDB()
    }
    
    public func applicationWillResignActive() {
        saveDrawingToDB()
    }
    
    // MARK: - public
    public func nodeDrawed(_ img:UIImage?) {
        arVC?.nodeDrawed(img)
    }
    
    public func addTopButton(at position:ButtonPosition,
                             button:UIButton,
                             tintColor:UIColor? = nil
    ) {
        let name = position == .left ? "leftButtonsStack" : "rightButtonsStack"
        let stackView = contentStack?.arrangedSubviews.first(where: {$0.layer.name == name}) as? UIStackView
        setTopButtonStyle(button, tintColor: tintColor)
        stackView?.addArrangedSubview(button)
        let animation = UIViewPropertyAnimator(duration: 0.22, curve: .easeIn) {
            button.isHidden = false
        }
        animation.startAnimation()
    }
    
    private func saveDrawingToDB() {
        if let drawings = drawVC?.drawView?.drawing {
            dataModelController.updateDrawing(drawings, at: drawingIndex)
        }
    }
    
    // MARK: IBAction
    @objc private func segmentedChanged(_ sender: UISegmentedControl) {
        ["leftButtonsStack", "rightButtonsStack"].forEach { name in
            let stackView = contentStack?.arrangedSubviews.first(where: {$0.layer.name == name}) as? UIStackView
            stackView?.arrangedSubviews.forEach { button in
                let animation = UIViewPropertyAnimator(duration: 0.22, curve: .easeOut) {
                    button.isHidden = true
                }
                animation.addCompletion { _ in
                    button.removeFromSuperview()
                }
                animation.startAnimation()
            }
        }
        selectedIndex = sender.selectedSegmentIndex
    }
    
    @objc private func toggleSettingsGesture(_ sender:UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let currentY = settingsStackView?.layer.frame.minY ?? 0
        settingsStackView?.layer.move(.top, value: translation.y + currentY)
        sender.setTranslation(.zero, in: view)
        switch sender.state {
        case .ended, .cancelled, .failed:
            let firstFrame = settingsStackView?.subviews.first?.frame.height ?? 0
            toggleSettigsView(show: !(currentY <= firstFrame / -2))
        case .began:
            toggleSettingsAnimation.stopAnimation(true)
        default:
            break
        }
    }
    
    @objc private func backButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - loadUI
extension TabBarController {
    func loadOptionsStack() {
        let rightStack = UIStackView()
        contentStack?.addArrangedSubview(rightStack)
        let leftStack = UIStackView()
        contentStack?.insertArrangedSubview(leftStack, at: 0)
        rightStack.spacing = 10
        leftStack.spacing = 10
        leftStack.layer.name = "leftButtonsStack"
        rightStack.layer.name = "rightButtonsStack"
        let backButton = UIButton()
        backButton.setImage(.init(systemName: "chevron.backward"), for: .normal)
        setTopButtonStyle(backButton)
        backButton.isHidden = false
        backButton.addTarget(self, action: #selector(backButtonPressed(_:)), for: .touchUpInside)
        contentStack?.insertArrangedSubview(backButton, at: 0)
    }
    
    func loadSegmentControl() {
        let mainView = UIView()
        view.addSubview(mainView)
        let primaryStack = UIStackView()
        mainView.addSubview(primaryStack)
        let primarySubview = UIView()
        let emptyView = UIView()
        [primarySubview, emptyView].forEach {
            primaryStack.addArrangedSubview($0)
        }
        let contentStack = UIStackView()
        primarySubview.addSubview(contentStack)
        let segmentedControll = UISegmentedControl()
        contentStack.addArrangedSubview(segmentedControll)
        primaryStack.addConstaits([.left:0, .right:0, .top:0, .bottom:0])
        contentStack.addConstaits([.left:10, .right:-10, .top:5, .bottom:-5])
        mainView.addConstaits([.centerX:0, .top:0])
        segmentedControll.addConstaits([.height:31])
        emptyView.addConstaits([.height: 20])
        primaryStack.axis = .vertical
        contentStack.axis = .horizontal
        primaryStack.distribution = .fill
        mainView.layer.name = "segmentSuperview"
        emptyView.layer.name = "emptyView"
        viewControllers?.forEach({
            segmentedControll.insertSegment(withTitle: $0.tabBarItem.title, at: segmentedControll.numberOfSegments, animated: true)
        })
        contentStack.spacing = 20
        segmentedControll.addTarget(self, action: #selector(segmentedChanged(_:)), for: .valueChanged)
        segmentedControll.selectedSegmentIndex = 0
        mainView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(toggleSettingsGesture(_:))))
    }
    
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
        let firstFrame = (settingsStackView?.superview?.frame.height ?? 0) + view.safeAreaInsets.top
        settingsStackView?.layer.move(.top, value: !show ? firstFrame / -1 : 0)
    }
    
    func setTopButtonStyle(_ button:UIButton, tintColor:UIColor? = nil) {
        let resultTint = tintColor ?? .label
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.tintColor = resultTint
        button.titleLabel?.textColor = resultTint
        button.setTitleColor(resultTint, for: .normal)
        button.backgroundColor = .systemGray.withAlphaComponent(0.2)
        button.layer.borderColor = UIColor.systemGray3.withAlphaComponent(0.1).cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 10
        button.layer.shadowOffset = .init(width: 3, height: 3)
        button.contentEdgeInsets = .init(top: 0, left: 5, bottom: 0, right: 5)
        button.isHidden = true
    }
    
    enum ButtonPosition {
    case left, right
    }
}

extension TabBarController {
    static func configure(model:DataModelController, index:Int) -> TabBarController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabBarController") as! TabBarController
        vc.dataModelController = model
        vc.drawingIndex = index
        return vc
    }
}
