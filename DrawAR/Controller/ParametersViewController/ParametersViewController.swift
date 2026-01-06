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
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

extension ParametersViewController: UICollectionViewDelegate, UICollectionViewDataSource {
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
            return cell

        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch data.collectionData[indexPath.row] {
        case .title(let data):
            data.didSelect()
        default: break
        }
    }
    
}

extension ParametersViewController {
    struct ScreenModel {
        let title: String
        let collectionData: [CollectionDataType]
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
        }
    }
    
    static func configure(_ data: ScreenModel) -> Self {
        let vc = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: .init(describing: Self.self)) as! Self
        vc.data = data
        return vc
    }
}
