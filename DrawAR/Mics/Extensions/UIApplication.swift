//
//  UIApplication.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 06.04.2024.
//

import UIKit

extension UIApplication {
    var keyWindow:UIWindow? {
        let scene = self.connectedScenes.first(where: {
            let window = $0 as? UIWindowScene
            return window?.activationState == .foregroundActive && (window?.windows.contains(where: { $0.isKeyWindow && $0.layer.name == AppDelegate.shared?.presentingWindowID}) ?? false)
        }) as? UIWindowScene
        return scene?.windows.last(where: {$0.isKeyWindow })
    }
}

extension UIViewController {
    func shareVC(data: URL, completion:(()->())? = nil) -> UIActivityViewController {
        let shareVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        shareVC.completionWithItemsHandler = { _, _, _, _ in
          //  completion?()
        }
        shareVC.popoverPresentationController?.sourceView = self.view
        shareVC.popoverPresentationController?.sourceRect = .init(origin: .zero, size: .zero)
        return shareVC
    }
}
