//
//  DrawViewModel.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 06.04.2024.
//

import Foundation

struct DrawViewModel {
    func zoomScale(_ currentScale:CGFloat, _ senderScale:CGFloat) -> CGFloat {
        var newScale = currentScale * senderScale
        if newScale <= 0.4 {
            newScale = 0.4
        } else if newScale >= 3 {
            newScale = 3
        }
        return newScale
    }
}
