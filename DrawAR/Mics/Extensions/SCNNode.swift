//
//  SCNNode.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 06.04.2024.
//

import SceneKit

extension SCNNode {
    var data:Data? {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
            return data
        } catch {
            return nil
        }
    }
    
    static func configure(_ archivedData:Data?) -> SCNNode? {
        if let archivedData,
           let unarchivedNode = try? NSKeyedUnarchiver.unarchivedObject(ofClass: SCNNode.self, from: archivedData) {
            return unarchivedNode
        } else {
            return nil
        }
    }
}
