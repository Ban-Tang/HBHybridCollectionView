//
//  HybridCollectionViewLayout.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 BanTang. All rights reserved.
//

import UIKit

protocol HybridCollectionViewLayoutDelegate: AnyObject {
    func stickyViewForHybridCollectionViewLayout(_ layout: HybridCollectionViewLayout) -> UIView?
    func stickyViewSizeForHybridCollectionViewLayout(_ layout: HybridCollectionViewLayout) -> CGSize
}

class HybridCollectionViewLayout: UICollectionViewFlowLayout {
    fileprivate weak var delegate: HybridCollectionViewLayoutDelegate?
    private(set) var stickyFrame: CGRect?

    init(delegate: HybridCollectionViewLayoutDelegate?) {
        super.init()
        self.delegate = delegate
        register(HybridCollectionReusableView.self, forDecorationViewOfKind: NSStringFromClass(HybridCollectionReusableView.self))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layoutAttributesClass: AnyClass {
        HybridCollectionViewLayoutAttributes.self
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = super.layoutAttributesForElements(in: rect)
        if let sticky = layoutAttributesForStickyView(), attributes?.contains(sticky) == false {
            attributes?.append(sticky)
        }
        return attributes
    }
    
    override var collectionViewContentSize: CGSize {
        var size = super.collectionViewContentSize
        size.height += stickyDecorationViewSize.height
        return size
    }
    
    private func layoutAttributesForStickyView() -> UICollectionViewLayoutAttributes? {
        let section = sectionCount - 1
        if section < 0 {
            return nil
        }
        
        /// Use the original contentSize to confirm the bottom position.
        let contentSize = super.collectionViewContentSize
        
        /// Create a decoration layout attributes.
        ///
        /// Use the zero index to create the decoration view, so the decoration view is truely visible on the screen, and this
        /// will make the insert/delete animation look more well.
        let indexPath = IndexPath(item: 0, section: 0)
        let attributes = HybridCollectionViewLayoutAttributes(forDecorationViewOfKind: NSStringFromClass(HybridCollectionReusableView.self), with: indexPath)
        
        /// Calculate the size of the decoration attributes.
        let insets = UIEdgeInsets.zero
        let x: CGFloat = insets.left
        let y: CGFloat = contentSize.height + insets.top
        let size = stickyDecorationViewSize
        attributes.frame = CGRect(x: floor(x), y: ceil(y), width: size.width, height: size.height)
        
        /// Make the decoration view always display on top.
        attributes.zIndex = 10000
        
        /// Add reference data.
        attributes.layout = self
        stickyFrame = attributes.frame
        
        return attributes
    }
    
    private var sectionCount: Int {
        guard let collectionView = collectionView else {
            return 1
        }
        return collectionView.dataSource?.numberOfSections?(in: collectionView) ?? 1
    }
    
    private var stickyDecorationViewSize: CGSize {
        if let size = delegate?.stickyViewSizeForHybridCollectionViewLayout(self) {
            return size
        }
        guard let collectionView = collectionView else {
            return .zero
        }
        var contentInset = collectionView.contentInset
        contentInset.top = 0
        contentInset.bottom = 0
        let frame = collectionView.frame.inset(by: contentInset)
        let w = frame.width - (contentInset.left + contentInset.right)
        let h = frame.height
        return CGSize(width: ceil(w), height: ceil(h))
    }
}

private class HybridCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    weak var layout: HybridCollectionViewLayout?
}

private class HybridCollectionReusableView: UICollectionReusableView {
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let attributes = layoutAttributes as? HybridCollectionViewLayoutAttributes else {
            return
        }
        guard let layout = attributes.layout, let view = layout.delegate?.stickyViewForHybridCollectionViewLayout(layout) else {
            return
        }
        if !view.isDescendant(of: self) {
            addSubview(view)
        }
        view.frame = CGRect(
            origin: .zero,
            size: layoutAttributes.frame.size
        )
    }
}
