//
//  HybridSectionController.swift
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 bantang. All rights reserved.
//

import UIKit

class HybridSectionController: ListSectionController {
    var item: HybridTitleItem?
    override func didUpdate(to object: Any) {
        self.item = object as? HybridTitleItem
    }
    
    override func numberOfItems() -> Int {
        return 1
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext?.containerSize.width ?? 0, height: item?.height ?? 0)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let item = item, let cell = collectionContext?.dequeueReusableCell(
            of: item.cell,
            for: self,
            at: 0)
            as? HybridListCellBindable & UICollectionViewCell else {
            fatalError()
        }
        cell.bind(item: item)
        return cell
    }
    
    override func didSelectItem(at index: Int) {
        SVProgressHUD.showInfo(withStatus: "🍉Did Tap The Cell - \(section + 1) 👏👏👏")
    }
}
