//
//  DrawListViewController.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 06.04.2024.
//

import UIKit

class DrawListViewController: UIViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    var dataModelController = DataModelController()

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        dataModelController.observers.append(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func addDrawingPressed(_ sender: UIButton) {
        dataModelController.newDrawing()
    }
}

extension DrawListViewController: DataModelControllerObserver {
    func dataModelChanged() {
        collectionView.reloadData()
    }
}


extension DrawListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataModelController.drawings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DrawListCollectionCell", for: indexPath) as! DrawListCollectionCell
        cell.set(dataModelController.thumbnails[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController(TabBarController.configure(model: dataModelController, index: indexPath.row), animated: true)
    }
}

extension DrawListViewController {
    static func configure() -> UINavigationController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DrawListViewController") as! DrawListViewController
        return .init(rootViewController: vc)
    }
}
