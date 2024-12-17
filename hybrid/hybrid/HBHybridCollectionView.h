//
//  HBHybridCollectionView.h
//  hybrid
//
//  Created by roylee on 2017/11/22.
//  Copyright © 2017年 BanTang. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HBHybridCollectionView;
@protocol HBHybridCollectionViewDelegate <NSObject>

/**
 Asks the page if the scrollview should scroll with the subview.
 
 @param collectionView  The collectionView. This is the object sending the message.
 @param subView         An instance of a sub view.
 @return YES to allow scrollview and subview to scroll together. YES by default.
 */
- (BOOL)collectionView:(HBHybridCollectionView *)collectionView shouldScrollWithSubView:(UIScrollView *)subView;

@optional
/**
 The following two methods must implement one. If both are implemented, the `-indexPathForBindingScrollInCollectionView`
 method will be invalid.
 */
- (CGFloat)collectionViewBindingScrollPosition:(HBHybridCollectionView *)collectionView;

- (NSIndexPath *)indexPathForBindingScrollInCollectionView:(HBHybridCollectionView *)collectionView;

- (BOOL)collectionView:(HBHybridCollectionView *)collectionView gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;

@end


@protocol HBHybridCollectionViewActionDelegate <NSObject>

@optional
- (void)collectionView:(HBHybridCollectionView *)collectionView didTouchBlank:(NSSet *)touches;

@end


@interface HBHybridCollectionView : UICollectionView

@property (nonatomic, weak, nullable) id <HBHybridCollectionViewDelegate> hybridDelegate;
@property (nonatomic, weak, nullable) id <HBHybridCollectionViewActionDelegate> actionDelegate;
@property (nonatomic, assign) CGFloat stickyTopInsert; //!< default is 0.
@property (nonatomic, readonly) CGFloat bindingScrollPosition;
@property (nonatomic, readonly, getter=isSticky) BOOL sticky;
@property (nonatomic, getter=isBindingEnable) BOOL bindingEnable; //!< default is YES.
@property (nonatomic, readonly, nullable) UIScrollView *currentScrollView;
@property (nonatomic, readonly) CGPoint adjustContentOffset; //!< contentOffset after adjusted, KVO enable.

- (void)scrollToTop;

@end

NS_ASSUME_NONNULL_END

