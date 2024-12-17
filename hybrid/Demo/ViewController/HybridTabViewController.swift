//
//  HybridTabViewController.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 BanTang. All rights reserved.
//

import UIKit
import Parchment

protocol HybridTabViewControllerDelegate: AnyObject {
    func tabViewController(_ tabViewController: HybridTabViewController, didSelecteTabAt index: Int)
}

class HybridTabViewController: UIViewController {
    struct Item {
        let title: String
        let viewController: UIViewController
    }
    var items: [Item] = []
    var pagingViewController = PagingViewController()
    weak var actionDelegate: HybridTabViewControllerDelegate?
    var barVisibleHeight: CGFloat {
        return 20 + MenuConfig.height
    }
    
    override func loadView() {
        self.view = HybridShoulderIndicatorView(frame: UIScreen.main.bounds)
    }
    
    init(delegate: HybridTabViewControllerDelegate? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.actionDelegate = delegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pop = parent?.navigationController?.interactivePopGestureRecognizer {
            pagingViewController.pageViewController.scrollView.panGestureRecognizer.require(toFail: pop)
        }
    }
    
    private func setupViews() {
        items.append(Item(title: "讨论", viewController: ListViewController()))
        items.append(Item(title: "精华", viewController: ListViewController()))
        items.append(Item(title: "影评", viewController: ListViewController()))
        items.append(Item(title: "视频", viewController: ListViewController()))
        
        pagingViewController.menuItemSize = .sizeToFit(minWidth: 0, height: MenuConfig.height)
        pagingViewController.menuItemSpacing = 35
        pagingViewController.menuItemLabelSpacing = 0
        pagingViewController.menuHorizontalAlignment = .center
        pagingViewController.borderColor = UIColor(white: 0.85, alpha: 1)
        pagingViewController.borderOptions = .visible(height: 1 / UIScreen.main.scale, zIndex: 1, insets: UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14))
        pagingViewController.indicatorColor = UIColor(white: 0.45, alpha: 1)
        pagingViewController.indicatorOptions = .visible(height: 2, zIndex: 1, spacing: .zero, insets: .zero)
        pagingViewController.selectedFont = MenuConfig.selectedFont
        pagingViewController.selectedTextColor = MenuConfig.selectedColor
        pagingViewController.font = MenuConfig.font
        pagingViewController.textColor = MenuConfig.color
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        pagingViewController.sizeDelegate = self
        view.addSubview(pagingViewController.view)
        pagingViewController.view.snp.makeConstraints({ (make) in
            make.top.equalTo(20)
            make.left.right.bottom.equalToSuperview()
        })
    }
}

///---------------------------
/// @name PaginViewController DataSource & Delegate
///---------------------------

extension HybridTabViewController: PagingViewControllerDataSource {
    func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        items.count
    }
    
    func pagingViewController(_: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        items[index].viewController
    }
    
    func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        PagingIndexItem(index: index, title: items[index].title)
    }
}

extension HybridTabViewController: PagingViewControllerDelegate {
    func pagingViewController(_ pagingViewController: PagingViewController, didSelectItem pagingItem: PagingItem) {
        guard let item = pagingItem as? PagingIndexItem else { return }
        actionDelegate?.tabViewController(self, didSelecteTabAt: item.index)
    }
}

extension HybridTabViewController: PagingViewControllerSizeDelegate {
    func pagingViewController(_: PagingViewController, widthForPagingItem pagingItem: PagingItem, isSelected: Bool) -> CGFloat {
        guard let item = pagingItem as? PagingIndexItem else { return 0 }
        return items[item.index].size.width
    }
}

extension HybridTabViewController.Item {
    var size: CGSize {
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: MenuConfig.height)
        let rect = title.boundingRect(with: size,
                                      options: .usesLineFragmentOrigin,
                                      attributes: [.font: MenuConfig.selectedFont],
                                      context: nil)
        return rect.integral.size
    }
}

private struct MenuConfig {
    static let height: CGFloat = 34
    static var font: UIFont {
        return UIFont.systemFont(ofSize: 16)
    }
    
    static var selectedFont: UIFont {
        return UIFont.systemFont(ofSize: 16, weight: .medium)
    }
    
    static var color: UIColor {
        return UIColor(white: 0.6, alpha: 1)
    }
    
    static var selectedColor: UIColor {
        return UIColor(white: 0.1, alpha: 1)
    }
}


///---------------------------
/// @name ListViewController
///---------------------------

class ListViewController: UIViewController {
    lazy var collectionViewLayout = UICollectionViewFlowLayout()
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    lazy var adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    
    var items: [HybridTitleItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupViews()
    }
    
    private func setupViews() {
        collectionViewLayout.estimatedItemSize = CGSize(width: view.bounds.width, height: 300)
        adapter.dataSource = self
        adapter.collectionView = collectionView
        collectionView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupData() {
        items.append(HybridTitleItem(cell: HybridListAvatarCell.self, title: "Kevin Nystrom", index: 1))
        items.append(HybridTitleItem(cell: HybridListAvatarCell.self, title: "Mike Squires", index: 2))
        items.append(HybridTitleItem(cell: HybridListAvatarCell.self, title: "Ann Emrich", index: 3))
        items.append(HybridTitleItem(cell: HybridListAvatarCell.self, title: "Jane Sherlock", index: 4))
        items.append(HybridTitleItem(cell: HybridListAvatarCell.self, title: "Philip Zhu", index: 5))
        items.append(HybridTitleItem(cell: HybridListAvatarCell.self, title: "Mona Van", index: 6))
        items.append(HybridTitleItem(cell: HybridListAvatarCell.self, title: "Tami Salman", index: 7))
        items.append(HybridTitleItem(cell: HybridListAvatarCell.self, title: "Jesse Broek", index: 8))
        items.append(HybridTitleItem(cell: HybridListAvatarCell.self, title: "Jaed Monshizadeh", index: 9))
        items.append(HybridTitleItem(cell: HybridListAvatarCell.self, title: "Jesse Holler", index: 10))
    }
}

extension ListViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return items
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return HybridSectionController()
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}
