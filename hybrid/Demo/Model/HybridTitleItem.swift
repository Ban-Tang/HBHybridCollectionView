//
//  HybridTitleItem.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 bantang. All rights reserved.
//

import UIKit

protocol HybridListCellBindable: AnyObject {
    func bind(item: HybridTitleItem?)
    static func cellHeight() -> CGFloat
}

class HybridTitleItem: NSObject {
    let cell: HybridListCellBindable.Type
    let title: String
    private(set) var index: Int
    let height: CGFloat
    let id: String
    
    init(cell: HybridListCellBindable.Type, title: String, index: Int, height: CGFloat? = nil, id: String = "") {
        self.cell = cell
        self.title = title
        self.index = index
        self.height = height ?? cell.cellHeight()
        self.id = id
    }
    
    func update(index: Int) {
        self.index = index
    }
}

extension HybridTitleItem: ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        return (title + id) as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let item = object as? HybridTitleItem else {
            return false
        }
        return title == item.title && id == item.id && index == item.index
    }
}
