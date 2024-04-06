//
//  LoadingTableView.swift
//  DrawAR
//
//  Created by Misha Dovhiy on 07.04.2024.
//

import UIKit

class LoadingTableView: UITableView {
    
    private var activityIndicator:UIActivityIndicatorView? {
        return self.subviews.first(where: {$0 is UIActivityIndicatorView}) as? UIActivityIndicatorView
    }
    var refresh:UIRefreshControl? {
        return self.subviews.first(where: {$0 is UIRefreshControl}) as? UIRefreshControl
    }
    
    var refreshBackgroundColor:UIColor?
    private var _refreshAction:(()->())?
    
    private var viewMoved = false
    private var reloadCalled = false

    override func removeFromSuperview() {
        super.removeFromSuperview()
        if viewMoved {
            refreshAction = nil
            activityIndicator?.removeFromSuperview()
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if !viewMoved {
            viewMoved = true
            addActivityView()
        }
    }
    
    override func reloadData() {
        super.reloadData()
        if !reloadCalled {
            reloadCalled = true
        } else if viewMoved {
            refresh?.endRefreshing()
            activityIndicator?.stopAnimating()
        }
    }
    
    var refreshAction:(()->())? {
        get {
            return _refreshAction
        }
        set {
            _refreshAction = newValue
            if refresh == nil && newValue != nil {
                addRefreshControll()
                startAnimating()
            } else if newValue == nil {
                refresh?.removeFromSuperview()
            }
        }
    }
    
    /**
     - to animate UIRefreshControll
     - UIRefreshControll located on top of the UITableView
     */
    func startRefreshing() {
        activityIndicator?.startAnimating()
    }
    
    /**
     - to animate UIActivityIndicatorView
     - UIActivityIndicatorView located in the middle of the UITableView
     */
    func startAnimating() {
        refresh?.beginRefreshing()
    }
    
    @objc private func refreshed(_ sender:UIRefreshControl) {
        if let refreshAction = refreshAction {
            sender.beginRefreshing()
            refreshAction()
        } else {
            sender.endRefreshing()
        }
    }
}


private extension LoadingTableView {
    func addActivityView() {
        if activityIndicator != nil {
            return
        }
        let activityIndicator:UIActivityIndicatorView = .init(style: .medium)
        activityIndicator.layer.name = "activityIndicator"
        activityIndicator.tintColor = .label
        activityIndicator.color = .label
        addSubview(activityIndicator)
        activityIndicator.addConstaits([.centerX:0, .centerY:0])
        activityIndicator.startAnimating()
    }
    
    func addRefreshControll() {
        if refresh != nil {
            return
        }
        let refresh = UIRefreshControl()
        refresh.layer.name = "UIRefreshControl"
        refresh.addTarget(self, action: #selector(self.refreshed(_:)), for: .valueChanged)
        addSubview(refresh)
        refresh.tintColor = .label
        refresh.backgroundColor = refreshBackgroundColor ?? .clear
    }
}

// MARK: - UICollectionView
class LoadingCollectionView: UICollectionView {
    
    private var activityIndicator:UIActivityIndicatorView? {
        return self.subviews.first(where: {$0 is UIActivityIndicatorView}) as? UIActivityIndicatorView
    }
    var refresh:UIRefreshControl? {
        return self.subviews.first(where: {$0 is UIRefreshControl}) as? UIRefreshControl
    }
    
    var refreshBackgroundColor:UIColor?
    private var _refreshAction:(()->())?
    
    private var viewMoved = false
    private var reloadCalled = false

    override func removeFromSuperview() {
        super.removeFromSuperview()
        if viewMoved {
            refreshAction = nil
            activityIndicator?.removeFromSuperview()
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if !viewMoved {
            viewMoved = true
            addActivityView()
        }
    }
    
    override func reloadData() {
        super.reloadData()
        if !reloadCalled {
            reloadCalled = true
        } else if viewMoved {
            refresh?.endRefreshing()
            activityIndicator?.stopAnimating()
        }
    }
    
    var refreshAction:(()->())? {
        get {
            return _refreshAction
        }
        set {
            _refreshAction = newValue
            if refresh == nil && newValue != nil {
                addRefreshControll()
                startAnimating()
            } else if newValue == nil {
                refresh?.removeFromSuperview()
            }
        }
    }
    
    /**
     - to animate UIRefreshControll
     - UIRefreshControll located on top of the UITableView
     */
    func startRefreshing() {
        activityIndicator?.startAnimating()
    }
    
    /**
     - to animate UIActivityIndicatorView
     - UIActivityIndicatorView located in the middle of the UITableView
     */
    func startAnimating() {
        refresh?.beginRefreshing()
    }
    
    @objc private func refreshed(_ sender:UIRefreshControl) {
        if let refreshAction = refreshAction {
            sender.beginRefreshing()
            refreshAction()
        } else {
            sender.endRefreshing()
        }
    }
}


private extension LoadingCollectionView {
    func addActivityView() {
        if activityIndicator != nil {
            return
        }
        let activityIndicator:UIActivityIndicatorView = .init(style: .medium)
        activityIndicator.layer.name = "activityIndicator"
        activityIndicator.tintColor = .label
        activityIndicator.color = .label
        addSubview(activityIndicator)
        activityIndicator.addConstaits([.centerX:0, .centerY:0])
        activityIndicator.startAnimating()
    }
    
    func addRefreshControll() {
        if refresh != nil {
            return
        }
        let refresh = UIRefreshControl()
        refresh.layer.name = "UIRefreshControl"
        refresh.addTarget(self, action: #selector(self.refreshed(_:)), for: .valueChanged)
        addSubview(refresh)
        refresh.tintColor = .label
        refresh.backgroundColor = refreshBackgroundColor ?? .clear
    }
}

