//
//  RLHybridCollectionView.h
//  hybrid
//
//  Created by roylee on 2017/11/22.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HBHybridCollectionView;
@protocol HBHybridCollectionViewDelegate <UICollectionViewDelegate>

@optional
/**
 Asks the page if the collectionView should scroll with the subview.
 
 @param collectionView The collectionView. This is the object sending the message.
 @param subView    An instance of a sub view.
 
 @return YES to allow collectionView and subview to scroll together. YES by default.
 */
- (BOOL)collectionView:(HBHybridCollectionView *)collectionView shouldScrollWithSubView:(UIScrollView *)subView;

- (NSInteger)sectionForBindingScrollInCollectionView:(HBHybridCollectionView *)collectionView;

@end

@interface HBHybridCollectionView : UICollectionView

/**
 Delegate instance that adopt the MXScrollViewDelegate.
 */
@property (nonatomic, weak, nullable) id<HBHybridCollectionViewDelegate>delegate;

@property (nonatomic, readonly, getter=isSticky) BOOL sticky;

@end

NS_ASSUME_NONNULL_END
