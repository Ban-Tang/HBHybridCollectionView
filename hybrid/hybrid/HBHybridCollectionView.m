//
//  RLHybridCollectionView.m
//  hybrid
//
//  Created by roylee on 2017/11/22.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import "HBHybridCollectionView.h"

@class HBHybridCollectionView;
@interface HBHybridCollectionViewDelegateForwarder : NSObject <HBHybridCollectionViewDelegate>

@property (nonatomic, weak) id<HBHybridCollectionViewDelegate> delegate;
@property (nonatomic, weak) HBHybridCollectionView *collectionView;

@end


@interface HBHybridCollectionView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) HBHybridCollectionViewDelegateForwarder *forwarder;
@property (nonatomic, strong) NSMutableArray<UIScrollView *> *observedViews;
@property (nonatomic, assign) CGFloat bindingScrollPosition;

@end


static void *const kHBContentOffsetContext = (void*)&kHBContentOffsetContext;

@implementation HBHybridCollectionView {
    BOOL _isObserving;
    BOOL _lock;
}

@synthesize delegate = _delegate;
@synthesize bounces = _bounces;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame: frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.forwarder = [HBHybridCollectionViewDelegateForwarder new];
    super.delegate = self.forwarder;
    
    self.showsVerticalScrollIndicator = NO;
    self.alwaysBounceVertical = YES;
    self.directionalLockEnabled = YES;
    self.bounces = YES;
    
    if (@available(iOS 10.0, *)) {
        self.prefetchingEnabled = NO;
    }
    
    if (@available(iOS 11.0, *)) {
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    self.panGestureRecognizer.cancelsTouchesInView = NO;
    
    self.observedViews = [NSMutableArray array];
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))
              options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
              context:kHBContentOffsetContext];
    _isObserving = YES;
}

#pragma mark - Properties

- (void)setDelegate:(id<HBHybridCollectionViewDelegate>)delegate {
    self.forwarder.delegate = delegate;
    // Scroll view delegate caches whether the delegate responds to some of the delegate
    // methods, so we need to force it to re-evaluate if the delegate responds to them
    super.delegate = nil;
    super.delegate = self.forwarder;
}

- (id<HBHybridCollectionViewDelegate>)delegate {
    return self.forwarder.delegate;
}

#pragma mark - UIGestureRecognizerDelegate

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
    
    // Tricky case: UICollectionViewWrapperView
    if ([scrollView.superview isKindOfClass:[UICollectionView class]]) {
        return NO;
    }
    
    BOOL shouldScroll = YES;
    if ([self.delegate respondsToSelector:@selector(scrollView:shouldScrollWithSubView:)]) {
        shouldScroll = [self.delegate scrollView:self shouldScrollWithSubView:scrollView];;
    }
    
    if (shouldScroll) {
        [self addObservedView:scrollView];
    }
    
    return shouldScroll;
}

#pragma mark KVO

- (void)addObserverToView:(UIScrollView *)scrollView {
    _lock = (scrollView.contentOffset.y > -scrollView.contentInset.top);
    
    [scrollView addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(contentOffset))
                    options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                    context:kHBContentOffsetContext];
}

- (void)removeObserverFromView:(UIScrollView *)scrollView {
    @try {
        [scrollView removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(contentOffset))
                           context:kHBContentOffsetContext];
    }
    @catch (NSException *exception) {}
}

// This is where the magic happens...
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == kHBContentOffsetContext && [keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {
        
        CGPoint new = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
        CGPoint old = [[change objectForKey:NSKeyValueChangeOldKey] CGPointValue];
        CGFloat diff = old.y - new.y;
        
        if (diff == 0.0 || !_isObserving) return;
        
        if (object == self) {
            
            //Adjust self scroll offset when scroll down
            if (diff > 0 && _lock) {
                [self scrollView:self setContentOffset:old];
                
            } else if (self.contentOffset.y < -self.contentInset.top && !self.bounces) {
                [self scrollView:self setContentOffset:CGPointMake(self.contentOffset.x, -self.contentInset.top)];
            } else if (self.contentOffset.y > -self.bindingScrollPosition) {
                [self scrollView:self setContentOffset:CGPointMake(self.contentOffset.x, -self.bindingScrollPosition)];
            }
            
        } else {
            //Adjust the observed scrollview's content offset
            UIScrollView *scrollView = object;
            _lock = (scrollView.contentOffset.y > -scrollView.contentInset.top);
            
            //Manage scroll up
            if (self.contentOffset.y < -self.bindingScrollPosition && _lock && diff < 0) {
                [self scrollView:scrollView setContentOffset:old];
            }
            //Disable bouncing when scroll down
            if (!_lock && ((self.contentOffset.y > -self.contentInset.top) || self.bounces)) {
                [self scrollView:scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, -scrollView.contentInset.top)];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Scrolling views handlers

- (void)addObservedView:(UIScrollView *)scrollView {
    if (![self.observedViews containsObject:scrollView]) {
        [self.observedViews addObject:scrollView];
        [self addObserverToView:scrollView];
    }
}

- (void)removeObservedViews {
    for (UIScrollView *scrollView in self.observedViews) {
        [self removeObserverFromView:scrollView];
    }
    [self.observedViews removeAllObjects];
}

- (void)scrollView:(UIScrollView *)scrollView setContentOffset:(CGPoint)offset {
    _isObserving = NO;
    scrollView.contentOffset = offset;
    _isObserving = YES;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:kHBContentOffsetContext];
    [self removeObservedViews];
}

#pragma mark <UIScrollViewDelegate>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _lock = NO;
    [self removeObservedViews];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        _lock = NO;
        [self removeObservedViews];
    }
}

@end

@implementation HBHybridCollectionViewDelegateForwarder

- (BOOL)respondsToSelector:(SEL)selector {
    return [self.delegate respondsToSelector:selector] || [super respondsToSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.delegate];
}

#pragma mark - UIScrollViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_collectionView.delegate && [_collectionView.delegate respondsToSelector:@selector(sectionForBindingScrollInCollectionView:)]) {
        NSInteger section = [_collectionView.delegate sectionForBindingScrollInCollectionView:_collectionView];
        
        if (indexPath.section == section) {
            _collectionView.bindingScrollPosition = CGRectGetMinX(cell.frame);
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [(HBHybridCollectionView *)scrollView scrollViewDidEndDecelerating:scrollView];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [(HBHybridCollectionView *)scrollView scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

@end
