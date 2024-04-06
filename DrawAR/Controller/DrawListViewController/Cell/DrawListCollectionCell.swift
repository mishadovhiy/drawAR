//
//  DrawListCollectionCell.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 06.04.2024.
//

import UIKit

class DrawListCollectionCell:UICollectionViewCell {
    
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    
    func set(_ image:UIImage?) {
        imageView.image = image
        noDataLabel.isHidden = image != nil
        backgroundColor = .label.withAlphaComponent(0.02)
        layer.cornerRadius = 4
    }
}
