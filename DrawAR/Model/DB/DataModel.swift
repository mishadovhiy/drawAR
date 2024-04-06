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
    
    static let defaultDrawingNames: [String] = ["Notes"]
    
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
    
    static let thumbnailSize = CGSize(width: 192, height: 256)
    
    var drawings: [PKDrawing] {
        get { dataModel.drawings }
        set { dataModel.drawings = newValue }
    }
    var signature: PKDrawing {
        get { dataModel.signature }
        set { dataModel.signature = newValue }
    }
    
    init() {
        loadDataModel()
    }
    
    func updateDrawing(_ drawing: PKDrawing, at index: Int) {
        dataModel.drawings[index] = drawing
        generateThumbnail(index)
        saveDataModel()
    }
    
    private func generateAllThumbnails() {
        for index in drawings.indices {
            generateThumbnail(index)
        }
    }
    
    private func generateThumbnail(_ index: Int) {
        let drawing = drawings[index]
        let aspectRatio = DataModelController.thumbnailSize.width / DataModelController.thumbnailSize.height
        let thumbnailRect = CGRect(x: 0, y: 0, width: DataModel.canvasWidth, height: DataModel.canvasWidth / aspectRatio)
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
                    dataModel = self.loadDefaultDrawings()
                }
            } else {
                dataModel = self.loadDefaultDrawings()
            }
            
            DispatchQueue.main.async {
                self.setLoadedDataModel(dataModel)
            }
        }
    }
    
    private func loadDefaultDrawings() -> DataModel {
        var testDataModel = DataModel()
        for sampleDataName in DataModel.defaultDrawingNames {
            guard let data = NSDataAsset(name: sampleDataName)?.data else { continue }
            if let drawing = try? PKDrawing(data: data) {
                testDataModel.drawings.append(drawing)
            }
        }
        return testDataModel
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
