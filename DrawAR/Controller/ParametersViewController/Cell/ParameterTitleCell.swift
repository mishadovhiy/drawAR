//
//  ParameterTitleCell.swift
//  DrawAR
//
//  Created by Mykhailo Dovhyi on 06.01.2026.
//

import UIKit

class ParameterTitleCell: UICollectionViewCell {
    
    @IBOutlet private var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .systemGray.withAlphaComponent(0.25)
        contentView.layer.cornerRadius = 6
        contentView.layer.masksToBounds = true
    }
    
    func set(_ data: ParametersViewController.CollectionDataType.TitleModel) {
        titleLabel.text = data.title
    }
}
