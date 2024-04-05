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
    var drawVC:DrawViewController? {
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
        drawVC?.positionHolder
    }
    
    // MARK: - private properties
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
     //   loadOptionsStack()
        tabBar.isHidden = true
    }
    
    // MARK: - public
    public func nodeDrawed(_ img:UIImage?) {
        arVC?.nodeDrawed(img)
    }
    
    // MARK: IBAction
    @objc private func segmentedChanged(_ sender: UISegmentedControl) {
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
}

// MARK: - loadUI
extension TabBarController {
    func loadOptionsStack() {
        let stackView = UIStackView()
        contentStack?.addArrangedSubview(stackView)
        let addDrawingButton = UIButton()
        stackView.addArrangedSubview(addDrawingButton)
        
        addDrawingButton.setTitle("add drawing", for: .normal)
        addDrawingButton.layer.name = "addDrawingButton"
        stackView.spacing = 10
        stackView.distribution = .fillEqually
    }
    
    func loadSegmentControl() {
        let mainView = UIView()
        view.addSubview(mainView)
        let primaryStack = UIStackView()
        mainView.addSubview(primaryStack)
        let primarySubview = UIView()
        let emptyView = UIView()
        [primarySubview].forEach {
            primaryStack.addArrangedSubview($0)
        }
        let contentStack = UIStackView()
        primarySubview.addSubview(contentStack)
        let segmentedControll = UISegmentedControl()
        contentStack.addArrangedSubview(segmentedControll)
        primaryStack.distribution = .fillEqually
        primaryStack.addConstaits([.left:0, .right:0, .top:0, .bottom:0])
        contentStack.addConstaits([.left:10, .right:-10, .top:5, .bottom:-5])
        mainView.addConstaits([.centerX:0, .top:0])
        segmentedControll.addConstaits([.height:31])
        primaryStack.axis = .vertical
        contentStack.axis = .horizontal
        mainView.layer.name = "segmentSuperview"
        emptyView.layer.name = "emptyView"
        viewControllers?.forEach({
            segmentedControll.insertSegment(withTitle: $0.tabBarItem.title, at: segmentedControll.numberOfSegments, animated: true)
        })
        contentStack.spacing = 30
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
}
