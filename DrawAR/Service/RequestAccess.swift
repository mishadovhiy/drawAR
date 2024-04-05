//
//  RequestAccess.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 04.04.2024.
//

import Foundation
import AVFoundation

struct RequestAccess {
    static func camera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
            }
            
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
}
