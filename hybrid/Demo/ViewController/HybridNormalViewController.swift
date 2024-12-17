//
//  HybridNormalViewController.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 BanTang. All rights reserved.
//

import UIKit

class HybridNormalViewController: HybridBaseViewController {
    private let collectionView = HBHybridCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let tabViewController = HybridTabViewController(delegate: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        collectionView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.hybridDelegate = self
        collectionView.stickyTopInsert = stickyTopInsert
        
        collectionView.register(HybridListCoverCell.self, forCellWithReuseIdentifier: HybridListCoverCell.identifier)
        collectionView.register(HybridStickyCell.self, forCellWithReuseIdentifier: HybridStickyCell.identifier)
        
        tabViewController.willMove(toParent: self)
        addChild(tabViewController)
        tabViewController.didMove(toParent: self)
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    override func datas() -> [HybridTitleItem] {
        var items = [HybridTitleItem]()
        items.append(HybridTitleItem(cell: HybridListCoverCell.self, title: "Cover", index: 0, height: HybridListCoverCell.cellHeight()))
        items.append(HybridTitleItem(cell: HybridStickyCell.self, title: "Just for sticky", index: -1))
        return items
    }
    
    override func collectionViewForUpdate() -> UICollectionView {
        return collectionView
    }
    
    override func updateIndex() -> UpdateIndex {
        return UpdateIndex(insert: items.count - 1, delete: 1)
    }
    
    override func willDeleteCell() -> Bool {
        return items.count > 2
    }
}

extension HybridNormalViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.identifier, for: indexPath) as? HybridListCellBindable & UICollectionViewCell else {
            fatalError()
        }
        cell.bind(item: item)
        /// Add the tab view to sticky cell.
        moveTabViewToCellIfNeed(cell)
        return cell
    }
    
    private func moveTabViewToCellIfNeed(_ cell: UICollectionViewCell) {
        guard let cell = cell as? HybridStickyCell, !tabViewController.view.isDescendant(of: cell.contentView) else {
            return
        }
        cell.contentView.addSubview(tabViewController.view)
        tabViewController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

extension HybridNormalViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = items[indexPath.item]
        if item.cell is HybridStickyCell.Type {
            return CGSize(width: view.bounds.width, height: view.bounds.height - stickyTopInsert)
        } else {
            return CGSize(width: view.bounds.width, height: item.cell.cellHeight())
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}

extension HybridNormalViewController: HBHybridCollectionViewDelegate {
    func collectionView(_ collectionView: HBHybridCollectionView, shouldScrollWithSubView subView: UIScrollView) -> Bool {
        /// Disable binding small scrollview (such as tabbar scrollview).
        let views = [tabViewController.pagingViewController.collectionView,
                     tabViewController.pagingViewController.pageViewController.scrollView]
        return !views.contains(subView)
    }
    
    func collectionView(_ collectionView: HBHybridCollectionView, gestureRecognizerShouldBegin gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: tabViewController.view)
        let barRect = CGRect(x: 0, y: 0, width: tabViewController.view.bounds.width, height: tabViewController.barVisibleHeight)
        let isTouchTabBar = barRect.contains(point)
        /// Disable scroll tab view when swiping tabbar or the tabvc is sticky on top.
        return !isTouchTabBar || !collectionView.isSticky
    }
    
    func indexPathForBindingScroll(in collectionView: HBHybridCollectionView) -> IndexPath {
        /// Sticky the last section.
        return IndexPath(item: items.count - 1, section: 0)
    }
}

extension HybridNormalViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        let top = tabViewController.view.convert(.zero, to: scrollView).y
        let distance = top - stickyTopInsert
        self.navigationBar.progress = max(0, min(offset / distance, 1))
    }
}
