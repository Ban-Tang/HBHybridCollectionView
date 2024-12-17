//
//  HybridItemCell.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 BanTang. All rights reserved.
//

import UIKit
import SnapKit

class HybridItemCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let arrow = UIImageView()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    private func setupViews() {
        let centerView = UIView()
        contentView.layer.cornerRadius = 4
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        arrow.sd_setImage(with: URL(string: "https://pic3.zhimg.com/v2-38a93e2dd32388276ea49dfdd61b7cfd.png"), completed: nil)
        centerView.addSubview(titleLabel)
        centerView.addSubview(subtitleLabel)
        contentView.addSubview(centerView)
        contentView.addSubview(arrow)
        contentView.backgroundColor = .white
        titleLabel.textColor = UIColor(white: 0.25, alpha: 1)
        subtitleLabel.textColor = UIColor(white: 0.5, alpha: 1)
        centerView.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.right.greaterThanOrEqualToSuperview()
        }
        subtitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.left.equalTo(titleLabel)
            make.bottom.equalToSuperview()
            make.right.greaterThanOrEqualToSuperview()
        }
        arrow.snp.makeConstraints { (make) in
            make.centerY.equalTo(centerView)
            make.right.equalTo(-6)
            make.height.width.equalTo(15)
        }
    }
    
    static func height(for item: HybridItemSource) -> CGFloat {
        return item.subtitle == nil ? 50 : 60
    }
    
    func bind(item: HybridItemSource) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.snp.updateConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(item.subtitle == nil ? 0 : 5)
        }
    }
}
