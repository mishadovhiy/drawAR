//
//  DrawListCollectionCell.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 06.04.2024.
//

import UIKit

class DrawListCollectionCell:UICollectionViewCell {
    
    @IBOutlet private weak var imageView: UIImageView!
    
    func set(_ image:UIImage) {
        imageView.image = image
    }
}
