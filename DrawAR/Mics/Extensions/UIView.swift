//
//  UIView.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 04.04.2024.
//

import UIKit

extension UIView {
    func addConstaits(_ constants:[NSLayoutConstraint.Attribute:CGFloat], safeArea:Bool = true, toSuperView:UIView? = nil) {
        guard let superview = self.superview ?? toSuperView else {
            return
        }
        constants.forEach { (key, value) in
            let keyNil = key == .height || key == .width
            let item:Any? = keyNil ? nil : (safeArea ? superview.safeAreaLayoutGuide : superview)
            let constraint:NSLayoutConstraint = .init(item: self, attribute: key, relatedBy: .equal, toItem: item, attribute: key, multiplier: 1, constant: value)
            if keyNil {
                self.addConstraint(constraint)
            } else {
                superview.addConstraint(constraint)
            }
        }
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}
