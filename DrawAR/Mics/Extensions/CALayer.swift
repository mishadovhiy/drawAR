//
//  CALayer.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 03.04.2024.
//

import UIKit
import QuartzCore

extension CALayer {
    func move(_ direction:UIRectEdge, value:CGFloat) {
        switch direction {
        case .top:
            self.transform = CATransform3DTranslate(CATransform3DIdentity, 0, value, 0)
        case .left:
            self.transform = CATransform3DTranslate(CATransform3DIdentity, value, 0, 0)
        default:
            break
        }
    }
    
    func zoom(value:CGFloat) {
     //   let newScale = value + ((CGFloat(1) - value) / 4)
        transform = CATransform3DMakeScale(value, value, 1)
    }
}

extension CGSize:Comparable {
    public static func < (lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width < rhs.width || lhs.height < rhs.height
    }
    
    public static func > (lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width > rhs.width || lhs.height > rhs.height
    }
    
    public static func + (lhs:CGSize, rhs:UIEdgeInsets) -> CGSize {
        return .init(width: lhs.width + (rhs.left + rhs.right), height: lhs.height + (rhs.top + rhs.bottom))
    }
    
    public static func - (lhs:CGSize, rhs:UIEdgeInsets) -> CGSize {
        let width = lhs.width - (rhs.left + rhs.right)
        let height = lhs.height - (rhs.top + rhs.bottom)
        return .init(width: width > 0 ? width : 10, height: height > 0 ? height : 10)
    }
}

