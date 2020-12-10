//
//  HybridListTitleCell.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 bantang. All rights reserved.
//

import UIKit
import SnapKit

extension HybridTitleItem {
    var identifier: String {
        switch cell {
        case is HybridStickyCell.Type:
                return "sticky"
        case is HybridListCoverCell.Type:
            return "cover"
        case is HybridListAvatarCell.Type:
            return "avatar"
        default:
            return "cell"
        }
    }
}

extension HybridListCellBindable where Self: UICollectionViewCell {
    static var identifier: String {
        switch self {
        case is HybridStickyCell.Type:
                return "sticky"
        case is HybridListCoverCell.Type:
            return "cover"
        case is HybridListAvatarCell.Type:
            return "avatar"
        default:
            return "cell"
        }
    }
}

extension HybridListCellBindable where Self: UICollectionViewCell {
    func bind(item: HybridTitleItem?) {}
    
    static func cellHeight() -> CGFloat {
        return 300
    }
}

class HybridSelfSizingCell: UICollectionViewCell {
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
        var frame = layoutAttributes.frame
        /// Don't change the width
        frame.size.height = ceil(size.height)
        layoutAttributes.frame = frame
        return layoutAttributes
    }
}

class HybridListCoverCell: UICollectionViewCell, HybridListCellBindable {
    let coverView = UIView()
    let titleView = UIView()
    let scoreView = UIView()
    let line = UIView()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func safeAreaInsetsDidChange() {
        coverView.snp.updateConstraints { (make) in
            make.top.equalTo((superview?.safeAreaInsets.top ?? 0) + 44 + 14)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        coverView.layer.cornerRadius = 4
        coverView.backgroundColor = UIColor(white: 0.75, alpha: 1)
        titleView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        scoreView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        scoreView.layer.cornerRadius = 5
        line.backgroundColor = UIColor(white: 0.9, alpha: 1)
        contentView.addSubview(coverView)
        contentView.addSubview(titleView)
        contentView.addSubview(scoreView)
        contentView.addSubview(line)
        coverView.snp.makeConstraints { (make) in
            make.top.left.equalTo(14)
            make.size.equalTo(CGSize(width: 95, height: 125))
        }
        titleView.snp.makeConstraints { (make) in
            make.top.equalTo(coverView)
            make.height.equalTo(28)
            make.left.equalTo(coverView.snp.right).offset(12)
            make.right.equalTo(-14)
        }
        scoreView.snp.makeConstraints { (make) in
            make.top.equalTo(coverView.snp.bottom).offset(14)
            make.left.equalTo(coverView)
            make.right.equalTo(titleView)
            make.height.equalTo(58)
        }
        line.snp.makeConstraints { (make) in
            make.left.equalTo(coverView)
            make.right.equalTo(titleView)
            make.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        
        let descs = 3
        createRandomView(in: contentView,
                         from: titleView,
                         count: descs,
                         start: CGSize(width: 50, height: 22),
                         range: CGSize(width: 200, height: 0),
                         margin: 8,
                         spacing: 4)
        
        let details = 4
        createRandomView(in: contentView,
                         from: scoreView,
                         count: details,
                         start: CGSize(width: 50, height: 25),
                         range: CGSize(width: 300, height: 0),
                         margin: 15,
                         spacing: 8)
    }
    
    func bind(item: HybridTitleItem?) {
        // do nothing.
    }
    
    static func cellHeight() -> CGFloat {
        return 475
    }
}

class HybridListTitleCell: HybridSelfSizingCell, HybridListCellBindable {
    let titleLabel = UILabel()
    let indexLabel = UILabel()
    let line = UIView()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = UIColor(white: 0.7, alpha: 1)
        indexLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        indexLabel.backgroundColor = UIColor(white: 0.75, alpha: 1)
        indexLabel.textColor = .white
        indexLabel.textAlignment = .center
        indexLabel.layer.masksToBounds = true
        indexLabel.layer.cornerRadius = 22 / 2
        line.backgroundColor = UIColor(white: 0.9, alpha: 1)
        contentView.addSubview(titleLabel)
        contentView.addSubview(indexLabel)
        contentView.addSubview(line)
        indexLabel.snp.makeConstraints { (make) in
            make.top.equalTo(30)
            make.left.equalTo(14)
            make.width.height.equalTo(22)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(indexLabel)
            make.left.equalTo(indexLabel.snp.right).offset(10)
            make.right.equalTo(-14)
        }
        line.snp.makeConstraints { (make) in
            make.left.equalTo(indexLabel)
            make.right.equalTo(titleLabel)
            make.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        
        let details = 5
        createRandomView(in: contentView,
                         from: indexLabel,
                         count: details,
                         start: CGSize(width: 50, height: 30),
                         range: CGSize(width: 300, height: 0),
                         margin: 15,
                         spacing: 10)
    }
    
    func bind(item: HybridTitleItem?) {
        titleLabel.text = item?.title
        indexLabel.text = "\(item?.index ?? 0)"
    }
}

class HybridListAvatarCell: HybridSelfSizingCell, HybridListCellBindable {
    let avatarView = UIView()
    let nameLabel = UILabel()
    let indexLabel = UILabel()
    let detailLabel = UILabel()
    let line = UIView()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        avatarView.backgroundColor = UIColor(white: 0.8, alpha: 1)
        avatarView.layer.cornerRadius = 54 / 2
        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = UIColor(white: 0.7, alpha: 1)
        indexLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        indexLabel.backgroundColor = UIColor(white: 0.8, alpha: 1)
        indexLabel.textColor = .white
        indexLabel.textAlignment = .center
        indexLabel.layer.masksToBounds = true
        indexLabel.layer.cornerRadius = 15 / 2
        detailLabel.backgroundColor = UIColor(white: 0.9, alpha: 1)
        line.backgroundColor = UIColor(white: 0.9, alpha: 1)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(indexLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(line)
        avatarView.snp.makeConstraints { (make) in
            make.top.equalTo(20)
            make.left.equalTo(14 - 1)
            make.width.height.equalTo(avatarView.layer.cornerRadius * 2)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avatarView).offset(4)
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.equalTo(-14)
        }
        indexLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.left.equalTo(nameLabel)
            make.height.width.equalTo(indexLabel.layer.cornerRadius * 2)
        }
        detailLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(indexLabel)
            make.height.equalTo(indexLabel).offset(-1)
            make.left.equalTo(indexLabel.snp.right).offset(5)
            make.width.equalTo(80 + CGFloat(arc4random() % 200))
        }
        line.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView)
            make.right.equalTo(nameLabel)
            make.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        
        let details = 5
        createRandomView(in: contentView,
                         from: avatarView,
                         count: details,
                         start: CGSize(width: 50, height: 30),
                         range: CGSize(width: 300, height: 0),
                         margin: 12,
                         padding: 1,
                         spacing: 8,
                         bottom: 30)
    }
    
    func bind(item: HybridTitleItem?) {
        nameLabel.text = item?.title
        indexLabel.text = "\(item?.index ?? 0)"
    }
}

final class HybridStickyCell: UICollectionViewCell, HybridListCellBindable {
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layoutAttributes.zIndex = 1000 * (layoutAttributes.indexPath.section + 1) + layoutAttributes.indexPath.item
        super.apply(layoutAttributes)
    }
}

///---------------------------
/// @name Random View
///---------------------------

private func createRandomView(in contentView: UIView, from: UIView, count: Int, start: CGSize, range: CGSize, margin: CGFloat, padding: CGFloat = 0, spacing: CGFloat, bottom: CGFloat = 0) {
    let rangeValue: (_ range: CGFloat) -> CGFloat = { range in
        if range > 0 {
            return CGFloat(arc4random() % UInt32(range))
        }
        return 0
    }
    var top: UIView?
    for i in 0..<count {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.9, alpha: 1)
        contentView.addSubview(v)
        v.snp.makeConstraints { (make) in
            if let top = top {
                make.top.equalTo(top.snp.bottom).offset(spacing)
            } else {
                make.top.equalTo(from.snp.bottom).offset(margin)
            }
            make.left.equalTo(from).offset(padding)
            make.height.equalTo(start.height + rangeValue(range.height))
            make.width.equalTo(start.width + rangeValue(range.width))
            if bottom > 0, i == count - 1 { make.bottom.equalTo(-bottom) }
        }
        top = v
    }
}
