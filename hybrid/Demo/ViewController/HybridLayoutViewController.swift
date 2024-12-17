//
//  HybridLayoutViewController.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 BanTang. All rights reserved.
//

import UIKit

class HybridLayoutViewController: HybridBaseViewController {
    lazy var layout = HybridCollectionViewLayout(delegate: self)
    lazy var collectionView = HBHybridCollectionView(frame: .zero, collectionViewLayout: layout)
    let tabViewController = HybridTabViewController(delegate: nil)
    
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
        
        tabViewController.willMove(toParent: self)
        addChild(tabViewController)
        tabViewController.didMove(toParent: self)
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    override func datas() -> [HybridTitleItem] {
        [HybridTitleItem(cell: HybridListCoverCell.self, title: "Cover", index: 0, height: HybridListCoverCell.cellHeight())]
    }
    
    override func collectionViewForUpdate() -> UICollectionView {
        return collectionView
    }
    
    override func updateIndex() -> UpdateIndex {
        return UpdateIndex(insert: items.count, delete: 1)
    }
    
    override func willDeleteCell() -> Bool {
        return items.count > 1
    }
}

extension HybridLayoutViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.identifier, for: indexPath) as? HybridListCellBindable & UICollectionViewCell else {
            fatalError()
        }
        cell.bind(item: item)
        return cell
    }
}

extension HybridLayoutViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = items[indexPath.item]
        return CGSize(width: view.bounds.width, height: item.cell.cellHeight())
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension HybridLayoutViewController: HBHybridCollectionViewDelegate {
    func collectionView(_ collectionView: HBHybridCollectionView, shouldScrollWithSubView subView: UIScrollView) -> Bool {
        /// Disable binding small scrollview (such as tab bar scrollview).
        let views = [tabViewController.pagingViewController.collectionView,
                     tabViewController.pagingViewController.pageViewController.scrollView]
        return !views.contains(subView)
    }
    
    func collectionView(_ collectionView: HBHybridCollectionView, gestureRecognizerShouldBegin gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: tabViewController.view)
        let barRect = CGRect(x: 0, y: 0, width: tabViewController.view.bounds.width, height: tabViewController.barVisibleHeight)
        let isTouchTabBar = barRect.contains(point)
        /// Disable scroll tab view when swiping tab bar or the tabVC is sticky on top.
        return !isTouchTabBar || !collectionView.isSticky
    }
    
    func collectionViewBindingScrollPosition(_ collectionView: HBHybridCollectionView) -> CGFloat {
        layout.stickyFrame?.minY ?? 10000
    }
}

extension HybridLayoutViewController: HybridCollectionViewLayoutDelegate {
    func stickyViewForHybridCollectionViewLayout(_ layout: HybridCollectionViewLayout) -> UIView? {
        tabViewController.view
    }
    
    func stickyViewSizeForHybridCollectionViewLayout(_ layout: HybridCollectionViewLayout) -> CGSize {
        CGSize(width: view.frame.width, height: view.frame.height - stickyTopInsert)
    }
}

extension HybridLayoutViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let stickyFrame = layout.stickyFrame else {
            return
        }
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        let distance = stickyFrame.minY - stickyTopInsert
        self.navigationBar.progress = max(0, min(offset / distance, 1))
    }
}
