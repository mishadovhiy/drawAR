//
//  DrawViewModel.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 06.04.2024.
//

import Foundation

struct DrawViewModel {
    var drawingSettedFromDB = false
    func zoomScale(_ currentScale:CGFloat, _ senderScale:CGFloat) -> CGFloat {
        var newScale = currentScale * senderScale
//        newScale *= 0.7
        if newScale <= 0.4 {
            newScale = 0.4
        } else if newScale >= 6 {
            newScale = 6
        }
        return newScale
    }
    
    func zoomScale(viewFrame: CGRect, touchPosition: CGPoint, scale: CGFloat) -> CGPoint {
        let cx = viewFrame.midX
        let cy = viewFrame.midY

        let dx = (touchPosition.x - cx) / cx
        let dy = (touchPosition.y - cy) / cy

        let wx = 1 + abs(dx)
        let wy = 1 + abs(dy)

        let sum = wx + wy
        let nx = wx / sum
        let ny = wy / sum


        let xScale = 1 + (scale - 1) * nx * 2
        let yScale = 1 + (scale - 1) * ny * 2
        return .init(x: xScale, y: yScale)
    }
}
