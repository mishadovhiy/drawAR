//
//  ParameterSliderCell.swift
//  DrawAR
//
//  Created by Mykhailo Dovhyi on 06.01.2026.
//

import UIKit

class ParameterSliderCell: UICollectionViewCell {
    
    @IBOutlet weak var sliderView: UISlider!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .systemGray.withAlphaComponent(0.25)
        contentView.layer.cornerRadius = 6
        contentView.layer.masksToBounds = true
    }
    
    func set(_ data: ParametersViewController.CollectionDataType.SliderModel) {
        sliderView.value = data.value
    }
}
