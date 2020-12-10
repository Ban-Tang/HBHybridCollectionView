//
//  HybridBaseViewController.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 bantang. All rights reserved.
//

import UIKit
import SnapKit

struct UpdateIndex {
    let insert: Int
    let delete: Int
}

extension HybridBaseViewController {
    var stickyTopInsert: CGFloat {
        let safeInsets = navigationController?.view.safeAreaInsets.top ?? 0
        return (safeInsets > 0 ? safeInsets : 20) + 44
    }
}

class HybridBaseViewController: UIViewController, UIGestureRecognizerDelegate {
    let navigationBar = HybridNavigationBar()
    var items: [HybridTitleItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationBar.backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        navigationBar.rightButton.addTarget(self, action: #selector(more), for: .touchUpInside)
        view.addSubview(navigationBar)
        collectionViewForUpdate().register(HybridListTitleCell.self, forCellWithReuseIdentifier: HybridListTitleCell.identifier)
        self.items = self.datas()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.bringSubviewToFront(navigationBar)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @objc func back() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func more() {
        let alert = UIAlertController(title: "What do you want？", message: "update the list data dynamic", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Insert one cell to the end", style: .default) { [weak self] _ in
            self?.insertCell()
        })
        alert.addAction(UIAlertAction(title: "Delete top one cell", style: .default) { [weak self] _ in
            self?.deleteCell()
        })
        alert.addAction(UIAlertAction(title: "Give up", style: .destructive, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func createItem(at index: Int, with cell: HybridListCellBindable.Type? = nil) -> HybridTitleItem {
        let names = ["Ryan Nystrom", "Jesse Squires", "Markus Emrich",
                     "James Sherlock", "Bofei Zhu", "Valeriy Van",
                     "Hesham Salman", "Bas Broek", "Andrew Monshizadeh",
                     "Adlai Holler"]
        let i = Int(arc4random()) % names.count
        return HybridTitleItem(cell: cell ?? HybridListTitleCell.self, title: names[i], index: index, id: "\(index)")
    }
    
    func insertCell() {
        let indexPath = IndexPath(item: updateIndex().insert, section: 0)
        items.insert(createItem(at: indexPath.item), at: indexPath.item)
        collectionViewForUpdate().performBatchUpdates({
            self.collectionViewForUpdate().insertItems(at: [indexPath])
        }, completion: { (_) in
            self.didInsertCell()
        })
    }
    
    func deleteCell() {
        guard willDeleteCell() else {
            return
        }
        let indexPath = IndexPath(item: updateIndex().delete, section: 0)
        items.remove(at: indexPath.item)
        collectionViewForUpdate().performBatchUpdates({
            self.collectionViewForUpdate().deleteItems(at: [indexPath])
        }, completion: { (_) in
            self.didDeleteCell()
        })
    }
    
    ///---------------------------
    /// @name Subclass Override
    ///---------------------------
    
    func collectionViewForUpdate() -> UICollectionView {
        fatalError("Subclass must return the main collectionView.")
    }
    
    func datas() -> [HybridTitleItem] {
        fatalError("Subclass must give the datas.")
    }
    
    func updateIndex() -> UpdateIndex {
        fatalError("Subclass must give the update index.")
    }
    
    func didInsertCell() {
        // do nothing...
    }
    
    func willDeleteCell() -> Bool {
        return true
    }
    
    func didDeleteCell() {
        // do nothing...
    }
}
