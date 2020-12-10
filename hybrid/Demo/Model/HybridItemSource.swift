//
//  HybridItemSource.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 bantang. All rights reserved.
//

import UIKit

struct HybridItemSource {
    let identifier: String
    let title: String
    let subtitle: String?
    let viewController: (() -> UIViewController)?
    init(identifier: String = "", title: String, subtitle: String? = nil, viewController: @autoclosure @escaping () -> UIViewController) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.viewController = viewController
    }
    
    init(identifier: String = "", title: String, subtitle: String? = nil) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.viewController = nil
    }
}
