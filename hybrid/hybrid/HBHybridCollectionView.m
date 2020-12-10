//
//  HBHybridCollectionView.m
//  hybrid
//
//  Created by roylee on 2017/11/22.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import "HBHybridCollectionView.h"
#import "HybridCollectionViewProxy.h"
#import "HybridCollectionViewObserver.h"
#import <objc/runtime.h>

@interface HBHybridCollectionView ()

@property (nonatomic, strong) HybridCollectionViewProxy *proxy;
@property (nonatomic, assign) BOOL ignoreObserver;
@property (nonatomic, assign) BOOL lock; //!< lock the collection view when scrolling.
@property (nonatomic) CGPoint adjustContentOffset;

@end

@implementation HBHybridCollectionView
@dynamic delegate;

static inline void JTChangeScrollViewContentOffset(HBHybridCollectionView *self, UIScrollView *scrollView, CGPoint contentOffset) {
    self.ignoreObserver = YES;
    scrollView.contentOffset = contentOffset;
    self.ignoreObserver = NO;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self commonInit];
        [self addObserverToView:self];
    }
    return self;
}

- (void)commonInit {
    self.showsVerticalScrollIndicator = NO;
    self.alwaysBounceVertical = YES;
    self.directionalLockEnabled = YES;
    self.bounces = YES;
    if (@available(iOS 11.0, *)) {
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    _bindingEnable = YES;
    _bindingScrollPosition = CGFLOAT_MAX;
    _stickyTopInsert = 0;
}

- (void)_updateBindingScrollPosition {
    if ([self.hybridDelegate respondsToSelector:@selector(collectionViewBindingScrollPosition:)]) {
        _bindingScrollPosition = [self.hybridDelegate collectionViewBindingScrollPosition:self];
    } else if ([self.delegate respondsToSelector:@selector(indexPathForBindingScrollInCollectionView:)]) {
        NSIndexPath *indexPath = [self.hybridDelegate indexPathForBindingScrollInCollectionView:self];
        UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
        if (cell) {
            _bindingScrollPosition = floor(CGRectGetMinY(cell.frame));
        }
    }
}


#pragma mark - Override

- (void)reloadData {
    // reset the `bindingScrollPosition` to maxnum before `realodaData`, so
    // this value will be set correct after `realodData` in collectionview
    // delegate.
    _bindingScrollPosition = CGFLOAT_MAX;
    [super reloadData];
}

- (void)performBatchUpdates:(void (NS_NOESCAPE ^_Nullable)(void))updates
                 completion:(void (^_Nullable)(BOOL finished))completion {
    // reset the `bindingScrollPosition` to maxnum before `realodaData`, so
    // this value will be set correct after `realodData` in collectionview
    // delegate.
    _bindingScrollPosition = CGFLOAT_MAX;
    __weak typeof(self) weakSelf = self;
    [super performBatchUpdates:updates completion:^(BOOL finished) {
        if (finished) {
            [weakSelf _updateBindingScrollPosition];
        }
        completion ? completion(finished) : nil;
    }];
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate {
    // Scroll view delegate caches whether the delegate responds to some of the delegate
    // methods, so we need to force it to re-evaluate if the delegate responds to them
    super.delegate = nil;
    
    self.proxy = nil;
    if (!delegate) return;
    
    self.proxy = [[HybridCollectionViewProxy alloc] initWithTarget:delegate interceptor:self];
    super.delegate = (id<UICollectionViewDelegate>)self.proxy;
}

- (id<UICollectionViewDelegate>)delegate {
    return (id<UICollectionViewDelegate>)super.delegate;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        [self.nextResponder touchesBegan:touches withEvent:event];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        [self.nextResponder touchesMoved:touches withEvent:event];
    }
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    if (!self.dragging) {
        [self.nextResponder touchesEnded:touches withEvent:event];
        if ([self.actionDelegate respondsToSelector:@selector(collectionView:didTouchBlank:)]) {
            [self.actionDelegate collectionView:self didTouchBlank:touches];
        }
    }
    [super touchesEnded:touches withEvent:event];
}


#pragma mark - Public

- (BOOL)isSticky {
    return self.contentOffset.y >= _bindingScrollPosition - _stickyTopInsert;
}

- (void)scrollToTop {
    if (self.contentOffset.y < - self.contentInset.top) {
        return;
    }
    _ignoreObserver = YES;
    [self setContentOffset:CGPointMake(self.contentOffset.x, - self.contentInset.top)
                  animated:YES];
    [_currentScrollView setContentOffset:CGPointMake(_currentScrollView.contentOffset.x, - _currentScrollView.contentInset.top)
                                animated:YES];
}


#pragma mark - Intercept

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.view != self) {
        return NO;
    }
    
    BOOL should = YES;
    if ([self.hybridDelegate respondsToSelector:@selector(collectionView:gestureRecognizerShouldBegin:)]) {
        should = [self.hybridDelegate collectionView:self gestureRecognizerShouldBegin:gestureRecognizer];
    }
    // Give a initialized `bindingScrollPosition`.
    if (should && [self.hybridDelegate respondsToSelector:@selector(collectionViewBindingScrollPosition:)]) {
        _bindingScrollPosition = [self.hybridDelegate collectionViewBindingScrollPosition:self];
    }
    return should;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if (otherGestureRecognizer.view == self) {
        return NO;
    }
    
    // Ignore other gesture than pan
    if (![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return NO;
    }
    
    // Lock horizontal pan gesture.
    CGPoint velocity = [(UIPanGestureRecognizer*)gestureRecognizer velocityInView:self];
    if (fabs(velocity.x) > fabs(velocity.y)) {
        return NO;
    }
    
    // Consider scroll view pan only
    if (![otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        return NO;
    }
    
    UIScrollView *scrollView = (id)otherGestureRecognizer.view;
    _currentScrollView = scrollView;
    
    // Tricky case: UITableViewWrapperView
    if ([scrollView.superview isKindOfClass:[UITableView class]]) {
        return NO;
    }
    
    BOOL shouldScroll = YES;
    if ([self.hybridDelegate respondsToSelector:@selector(collectionView:shouldScrollWithSubView:)]) {
        shouldScroll = [self.hybridDelegate collectionView:self shouldScrollWithSubView:scrollView];;
    }
    
    if (!shouldScroll) {
        return NO;
    }
    
    // Add observe to every scroll view to handle binding scroll.
    [self addObserverToView:scrollView];
    
    // Reset lock state.
    _lock = (scrollView.contentOffset.y > - scrollView.contentInset.top);
    
    // Reset the `bounces` to YES, otherwise this collection view will can not be scrolled when the
    // contentSize is less than the bounds.size.
    scrollView.bounces = YES;
    
    return YES;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(HBHybridCollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    // Dirctly call real delegate.
    id delegate = self.proxy.target;
    if ([delegate respondsToSelector:@selector(collectionViewBindingScrollPosition:)]) {
        return;
    }
    
    if ([delegate respondsToSelector:@selector(indexPathForBindingScrollInCollectionView:)]) {
        NSIndexPath *idp = [delegate indexPathForBindingScrollInCollectionView:collectionView];
        if ([indexPath isEqual:idp]) {
            _bindingScrollPosition = floor(CGRectGetMinY(cell.frame));
        }
    }
    
    if ([delegate respondsToSelector:_cmd]) {
        [delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _ignoreObserver = NO;
    if ([_proxy.target respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [_proxy.target scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _lock = NO;
    if ([_proxy.target respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [_proxy.target scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        _lock = NO;
    }
    if ([_proxy.target respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [_proxy.target scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}


#pragma mark - KVO

- (void)addObserverToView:(UIView *)view {
    [HybridCollectionViewObserver addObserver:self withTarget:view keyPath:NSStringFromSelector(@selector(contentOffset))];
}

- (void)removeObserverFromView:(UIView *)view {
    [HybridCollectionViewObserver removeObserver:self withTarget:view keyPath:NSStringFromSelector(@selector(contentOffset))];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (_ignoreObserver == NO && context == @selector(contentOffset)) {
        [self scrollView:object contentOffsetDidChanged:change];
    }
}

// This is where the magic happens...
- (void)scrollView:(UIScrollView *)scrollView contentOffsetDidChanged:(NSDictionary *)change {
    if (self.isBindingEnable == NO) {
        return;
    }
    
    CGPoint new = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
    CGPoint old = [[change objectForKey:NSKeyValueChangeOldKey] CGPointValue];
    CGFloat diff = new.y - old.y;
    
    if (diff == 0.0) {
        return;
    }
    
    CGFloat bindingScrollPosition = _bindingScrollPosition - _stickyTopInsert;
    
    if (scrollView == self) {
        CGPoint adjustContentOffset = new;
        // Adjust self scroll offset when scroll down
        if (diff < 0 && _lock) {
            adjustContentOffset = old;
        }
        // Scroll up or the collection view don't need lock.
        else if (self.contentOffset.y < - self.contentInset.top && !self.bounces) {
            adjustContentOffset = CGPointMake(self.contentOffset.x, - self.contentInset.top);
        }
        // Sticky on the top.
        else if (self.contentOffset.y > bindingScrollPosition) {
            adjustContentOffset = CGPointMake(self.contentOffset.x, bindingScrollPosition);
        }
        // Adjust the scollView's contentOffset for sticky.
        if (CGPointEqualToPoint(new, adjustContentOffset) == NO) {
            JTChangeScrollViewContentOffset(self, scrollView, adjustContentOffset);
        }
        // Reset & calll KVO.
        self.adjustContentOffset = adjustContentOffset;
    } else {
        // Adjust the observed scrollview's content offset
        _lock = (scrollView.contentOffset.y > - scrollView.contentInset.top);
        
        // Manage scroll up
        if (self.contentOffset.y < bindingScrollPosition && _lock && diff > 0) {
            JTChangeScrollViewContentOffset(self, scrollView, old);
        }
        // Disable bouncing when scroll down
        if (!_lock && ((self.contentOffset.y > - self.contentInset.top) || self.bounces)) {
            JTChangeScrollViewContentOffset(self, scrollView, CGPointMake(scrollView.contentOffset.x, - scrollView.contentInset.top));
        }
    }
}

@end

