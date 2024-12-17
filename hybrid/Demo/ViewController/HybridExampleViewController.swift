//
//  HybridExampleViewController.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 BanTang. All rights reserved.
//

import UIKit

class HybridExampleViewController: UIViewController {
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var items: [HybridItemSource] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.setup(in: navigationController?.view)
        self.title = "HybridCollectionView"
        loadItems()
        setupViews()
    }
    
    func loadItems() {
        items.append(HybridItemSource(title: "Normal Layout",
                                      subtitle: "Use cell at last section as the paging tab.",
                                      viewController: HybridNormalViewController()))
        items.append(HybridItemSource(title: "Custom Layout",
                                      subtitle: "Use decoration view for paging tab.",
                                      viewController: HybridLayoutViewController()))
    }
    
    private func setupViews() {
        collectionView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(HybridItemCell.self, forCellWithReuseIdentifier: HybridItemCell.description())
        collectionView.contentInset = UIEdgeInsets(top: 30, left: 0, bottom: 44, right: 0)
        collectionView.alwaysBounceVertical = true
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

extension HybridExampleViewController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HybridItemCell.description(), for: indexPath) as? HybridItemCell else {
            fatalError()
        }
        cell.bind(item: items[indexPath.section])
        return cell
    }
}

extension HybridExampleViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.section]
        guard let viewController = item.viewController?() as? HybridBaseViewController else {
            return
        }
        viewController.navigationBar.titleLabel.text = title
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension HybridExampleViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.size.width - 2 * 12,
                      height: HybridItemCell.height(for: items[indexPath.section]))
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
    }
}

extension SVProgressHUD {
    static func setup(in view: UIView?) {
        setDefaultStyle(.dark)
        setDefaultMaskType(.none)
        setDefaultAnimationType(.flat)
        setCornerRadius(10)
        setMinimumSize(CGSize(width: 120, height: 30))
        setMinimumDismissTimeInterval(0.8)
        setBackgroundColor(UIColor(white: 0.25, alpha: 1))
        setForegroundColor(.white)
        setImageViewSize(CGSize(width: 0, height: -5))
        setFont(UIFont.systemFont(ofSize: 16, weight: .semibold))
        setViewForExtension(view ?? UIView())
    }
}
