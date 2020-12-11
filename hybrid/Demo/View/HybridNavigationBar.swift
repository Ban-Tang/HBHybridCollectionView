//
//  HybridNavigationBar.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 bantang. All rights reserved.
//

import UIKit

class HybridBarButton: UIButton {
    var image: String = "" {
        didSet {
            sd_setImage(with: URL(string: image), color: tintColor)
        }
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var imageRect = super.imageRect(forContentRect: contentRect)
        guard let image = self.image(for: .normal) else {
            return imageRect
        }
        let imageSize = CGSize(width: image.size.width * 1 / 3, height: image.size.height * 1 / 3)
        imageRect = imageRect.insetBy(dx: (imageRect.width - imageSize.width) / 2, dy: (imageRect.height - imageSize.height) / 2)
        return imageRect
    }
}

class HybridNavigationBar: UIView {
    let gradient = CAGradientLayer()
    let backButton = HybridBarButton(frame: .zero)
    let titleLabel = UILabel()
    let rightButton = HybridBarButton(frame: .zero)
    
    var progress: CGFloat = 0 {
        didSet {
            backgroundColor = UIColor(white: 1, alpha: progress)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        frame = CGRect(x: 0, y: 0, width: superview?.bounds.width ?? 0, height: (safeAreaInsets.top > 0 ? safeAreaInsets.top : 20) + 44)
        gradient.locations = [0, NSNumber(value: Float((frame.height - 44) / frame.height)), 1]
        gradient.frame = bounds
    }
    
    private func setupViews() {
        gradient.locations = [0, 0, 1]
        gradient.colors = [UIColor.white.cgColor, UIColor.white.cgColor, UIColor(white: 1, alpha: 0).cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        layer.addSublayer(gradient)
        
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor(white: 0.45, alpha: 1)
        backButton.tintColor = titleLabel.textColor
        backButton.image = "http://api.error408.com/icon/nav_icon_back.png"
        rightButton.tintColor = titleLabel.textColor
        rightButton.image = "http://api.error408.com/icon/nav_icon_more.png"
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(rightButton)
        backButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(44)
            make.bottom.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(backButton.snp.right).offset(0)
            make.centerY.equalTo(backButton)
        }
        rightButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(44)
            make.right.bottom.equalToSuperview()
        }
    }
}

extension UIButton {
    func sd_setImage(with uRL: URL?, color: UIColor? = nil) {
        sd_setImage(with: uRL, for: .normal, placeholderImage: nil, options: .avoidAutoSetImage) { (image, _, _, _) in
            self.setImage(image?.filled(color: color), for: .normal)
        }
    }
}
