//
//  UICollectionViewCell+UITableViewCell.swift
//  DrawAR
//
//  Created by Mykhailo Dovhyi on 06.01.2026.
//

import UIKit

extension UICollectionViewCell {
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.selectedBackgroundView = .init()
    }
}
