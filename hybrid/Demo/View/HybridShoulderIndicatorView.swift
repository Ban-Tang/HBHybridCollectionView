//
//  HybridShoulderIndicatorView.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 bantang. All rights reserved.
//

import UIKit
import SnapKit

class HybridShoulderIndicatorView: UIView {
    let indicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        /// Setup corner
        layer.cornerRadius = 8
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.shadowColor = UIColor(white: 0, alpha: 0.05).cgColor
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowOpacity = 1
        
        /// Add indicator.
        indicator.backgroundColor = UIColor(white: 0.8, alpha: 1)
        indicator.layer.cornerRadius = 4 / 2
        addSubview(indicator)
        indicator.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 36, height: 4))
            make.centerX.equalToSuperview()
            make.top.equalTo(layer.cornerRadius)
        }
    }
}
