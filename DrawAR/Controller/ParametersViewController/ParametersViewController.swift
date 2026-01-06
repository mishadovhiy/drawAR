//
//  ParametersViewController.swift
//  DrawAR
//
//  Created by Mykhailo Dovhyi on 06.01.2026.
//

import UIKit

class ParametersViewController: UIViewController {

    @IBOutlet private var collectionView: UICollectionView!
    private var data: ScreenModel!
    private let collectionSize: CGSize = .init(width: 128, height: 28)
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        updateTableData(data)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let hideNavigation = self.navigationController?.viewControllers.count == 1
        self.navigationController?.setNavigationBarHidden(hideNavigation, animated: true)
        updateHeight(hideNavigation)
        updateWidth()
    }
    
    public func updateTableData(_ newData: ScreenModel) {
//        if view.superview == nil {
//            return
//        }
        data = newData
        collectionView.reloadData()
        updateWidth()
    }
    
    func updateWidth() {
        var newSize = CGFloat(self.data.collectionData.count) * (collectionSize.width + 20)
        if newSize <= collectionSize.width + 40 {
            newSize = collectionSize.width + 40
        }
        //collectionView.collectionViewLayout.collectionViewContentSize
        let const = self.navigationController?.view.superview?.constraints.first(where: {
            $0.firstAttribute == .width || $0.secondAttribute == .width
        })
        if const?.constant != newSize {
            const?.constant = newSize
            self.didUpdateConstraints()
        }
    }
    
    func didUpdateConstraints() {
        let animation = UIViewPropertyAnimator(duration: 0.3, curve: .linear) { [weak self] in
            guard let self else { return }
            navigationController?.view.layoutIfNeeded()
            navigationController?.view.superview?.layoutIfNeeded()
            navigationController?.view.setNeedsLayout()
            navigationController?.view.layoutSubviews()
            navigationController?.view.updateConstraints()
            view.setNeedsLayout()
            view.layoutSubviews()
            view.layoutIfNeeded()
            navigationController?.view.superview?.setNeedsLayout()
        }
        animation.addCompletion { _ in
            self.collectionView.reloadData()
        }
        animation.startAnimation()
    }
    
    func updateHeight(_ hideNavigation: Bool) {
        let const = self.navigationController?.view.superview?.constraints.first(where: {
            $0.firstAttribute == .height || $0.secondAttribute == .height
        })

        let new: CGFloat = (hideNavigation ? 15 : (navigationController?.navigationBar.frame.height ?? 0) + 50) + collectionSize.height
        if const?.constant != new {
            const?.constant = new
            self.didUpdateConstraints()

        }
    }
}

extension ParametersViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        data.collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch data.collectionData[indexPath.row] {
            
        case .title(let data):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .init(describing: ParameterTitleCell.self), for: indexPath) as! ParameterTitleCell
            cell.set(data)
            return cell
        case .slider(let data):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .init(describing: ParameterSliderCell.self), for: indexPath) as! ParameterSliderCell
            cell.set(data)
            cell.sliderView.tag = indexPath.row
            cell.sliderView.addTarget(self, action: #selector(sliderDidChange(_:)), for: .valueChanged)
            return cell

        }
    }
    
    @objc func sliderDidChange(_ sender: UISlider) {
        switch data.collectionData[sender.tag] {
        case .slider(let slider):
            slider.valueDidChange(sender.value)
        default: break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch data.collectionData[indexPath.row] {
        case .title(let data):
            data.didSelect()
        default: break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        .init(width: 128, height: 35)
    }
    
}

extension ParametersViewController {
    struct ScreenModel {
        let title: String
        let collectionData: [CollectionDataType]
        
        init(_ title: String = "",
             collectionData: [CollectionDataType] = []) {
            self.title = title
            self.collectionData = collectionData
        }
    }
    
    enum CollectionDataType {
        case title(TitleModel)
        case slider(SliderModel)
        
        struct SliderModel {
            let value: Float
            let valueDidChange: (_ newValue: Float)->()
        }
        
        struct TitleModel {
            let title: String
            let didSelect: ()->()
            
            init(_ title: String, didSelect: @escaping () -> Void) {
                self.title = title
                self.didSelect = didSelect
            }
        }
    }
    
    static func configure(_ data: ScreenModel) -> Self {
        let vc = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: .init(describing: Self.self)) as! Self
        vc.data = data
        vc.title = data.title
        return vc
    }
}
