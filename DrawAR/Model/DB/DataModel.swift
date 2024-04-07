//
//  DataModel.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 06.04.2024.
//

import UIKit
import PencilKit
import os

struct DataModel: Codable {
    static let canvasWidth: CGFloat = 768
    var drawings: [PKDrawing] = []
    var signature = PKDrawing()
}

protocol DataModelControllerObserver {
    func dataModelChanged()
}

class DataModelController {
    
    var dataModel = DataModel()
    
    var thumbnails = [UIImage?]()
    var thumbnailTraitCollection = UITraitCollection() {
        didSet {
            if oldValue.userInterfaceStyle != thumbnailTraitCollection.userInterfaceStyle {
                generateAllThumbnails()
            }
        }
    }
    
    private let thumbnailQueue = DispatchQueue(label: "ThumbnailQueue", qos: .background)
    private let serializationQueue = DispatchQueue(label: "SerializationQueue", qos: .background)
    
    var observers = [DataModelControllerObserver]()
    
    static let thumbnailSize = CGSize(width: 300, height: 150)
    
    var drawings: [PKDrawing] {
        get { dataModel.drawings }
        set { dataModel.drawings = newValue }
    }
    
    init() {
        loadDataModel()
    }
    
    func updateDrawing(_ drawing: PKDrawing?, at index: Int) {
        if let drawing {
            dataModel.drawings[index] = drawing
        } else {
            dataModel.drawings.remove(at: index)
        }
        let size = UIApplication.shared.keyWindow?.screen.bounds.size ?? .init()
        if let drawing {
            generateThumbnail(index, size: size)
        } else {
            generateAllThumbnails()
        }
        saveDataModel()
    }
    
    private func generateAllThumbnails() {
        let size = UIApplication.shared.keyWindow?.screen.bounds.size ?? .init()
        for index in drawings.indices {
            generateThumbnail(index, size: size)
        }
        if drawings.count == 0 {
            newDrawing()
        }
    }
    
    private func generateThumbnail(_ index: Int, size:CGSize) {
        let drawing = drawings[index]
        let aspectRatio = DataModelController.thumbnailSize.width / DataModelController.thumbnailSize.height
        let thumbnailRect = CGRect(x: size.width / 3, y: size.height / 3, width: DataModel.canvasWidth, height: DataModel.canvasWidth / aspectRatio)
        let thumbnailScale = UIScreen.main.scale * DataModelController.thumbnailSize.width / DataModel.canvasWidth
        let traitCollection = thumbnailTraitCollection
        
        thumbnailQueue.async {
            traitCollection.performAsCurrent {
                let image = drawing.image(from: thumbnailRect, scale: thumbnailScale)
                DispatchQueue.main.async {
                    if #available(iOS 14.0, *) {
                        self.updateThumbnail(drawing.strokes.count == 0 ? nil : image, at: index)
                    } else {
                        self.updateThumbnail(image, at: index)
                    }
                }
            }
        }
    }
    
    private func updateThumbnail(_ image: UIImage?, at index: Int) {
        thumbnails[index] = image
        didChange()
    }
    
    private func didChange() {
        for observer in self.observers {
            observer.dataModelChanged()
        }
    }
    
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths.first!
        return documentsDirectory.appendingPathComponent("PencilKitDraw.data")
    }
    
    func saveDataModel() {
        let savingDataModel = dataModel
        let url = saveURL
        serializationQueue.async {
            do {
                let encoder = PropertyListEncoder()
                let data = try encoder.encode(savingDataModel)
                try data.write(to: url)
            } catch {
                os_log("Could not save data model: %s", type: .error, error.localizedDescription)
            }
        }
    }
    
    private func loadDataModel() {
        let url = saveURL
        serializationQueue.async {
            let dataModel: DataModel
            
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let decoder = PropertyListDecoder()
                    let data = try Data(contentsOf: url)
                    dataModel = try decoder.decode(DataModel.self, from: data)
                } catch {
                    os_log("Could not load data model: %s", type: .error, error.localizedDescription)
                    dataModel = .init()
                }
            } else {
                dataModel = .init()
            }
            
            DispatchQueue.main.async {
                self.setLoadedDataModel(dataModel)
            }
        }
    }
    
    private func setLoadedDataModel(_ dataModel: DataModel) {
        self.dataModel = dataModel
        thumbnails = Array(repeating: UIImage(), count: dataModel.drawings.count)
        generateAllThumbnails()
    }
    
    func newDrawing() {
        let newDrawing = PKDrawing()
        dataModel.drawings.append(newDrawing)
        thumbnails.append(UIImage())
        updateDrawing(newDrawing, at: dataModel.drawings.count - 1)
    }
}
