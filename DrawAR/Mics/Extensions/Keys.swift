//
//  PKStroke.swift
//  DrawAR
//
//  Created by Mykhailo Dovhyi on 06.01.2026.
//

import Foundation
import PencilKit

@available(iOS 14.0, *)
extension PKCanvasView {
    var convertDrawingToSVG: String {
        
        let svgPaths = drawing.strokes.compactMap({
            svgPath(from: $0)
        }).joined(separator: "\n")
        return """
        <svg xmlns="http://www.w3.org/2000/svg" width="\(drawing.bounds.width)" height="\(drawing.bounds.height)" viewBox="0 0 \(drawing.bounds.width) \(drawing.bounds.height)">
            <desc>Created with Draw In AR app, by Mykhailo Dovhyi.</desc>
        <title>drawingGroup</title>
        <metadata>Download app: https://apps.apple.com/us/app/id6483004426</metadata>

        \(svgPaths)
        </svg>
        """
    }
    
    private func svgPath(from stroke: PKStroke) -> String {
        guard let first = stroke.path.first else { return "" }
        
        var d = "M \(first.location.x) \(first.location.y)"
        
        for point in stroke.path {
            let x = point.location.x
            let y = point.location.y
            d += " L \(x) \(y)"
        }
        
        let color = stroke.ink.color
        let width = stroke.path.first?.size.width ?? 1.0
        
        let strokeColor = svgColor(from: color)
        
        return """
        <path d="\(d)"
              fill="none"
              stroke="\(strokeColor)"
              stroke-width="\(width)"
              stroke-linecap="round"
              stroke-linejoin="round" />
        """
    }
    
    private func svgColor(from color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "rgba(%d,%d,%d,%.2f)", Int(r*255), Int(g*255), Int(b*255), a)
    }
}
