//
//  RLHybridCollectionView.m
//  hybrid
//
//  Created by roylee on 2017/11/22.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import "HBHybridCollectionView.h"

@interface HBHybridCollectionViewProxy : NSObject <HBHybridCollectionViewDelegate>
@property (nonatomic, weak) id<HBHybridCollectionViewDelegate> delegate;
@end




@interface HBHybridCollectionView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) HBHybridCollectionViewProxy *forwarder;
@property (nonatomic, strong) NSMutableArray<UIScrollView *> *observedViews;
@property (nonatomic, assign) CGFloat bindingScrollPosition;

@end


static void *const kHBContentOffsetContext = (void*)&kHBContentOffsetContext;

@implementation HBHybridCollectionView {
    BOOL _ignoreObserver;
    BOOL _lock; ///< lock the collection view when scrolling.
}

@synthesize delegate = _delegate;
@synthesize bounces = _bounces;

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
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
    self.forwarder = [HBHybridCollectionViewProxy new];
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
    self.bindingScrollPosition = CGFLOAT_MAX;
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))
              options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
              context:kHBContentOffsetContext];
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
    
    // Tricky case: UITableViewWrapperView
    if ([scrollView.superview isKindOfClass:[UITableView class]]) {
        return NO;
    }
    
    BOOL shouldScroll = YES;
    if ([self.delegate respondsToSelector:@selector(collectionView:shouldScrollWithSubView:)]) {
        shouldScroll = [self.delegate collectionView:self shouldScrollWithSubView:scrollView];;
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
    
    if (context == kHBContentOffsetContext) {
        
        CGPoint new = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
        CGPoint old = [[change objectForKey:NSKeyValueChangeOldKey] CGPointValue];
        CGFloat diff = new.y - old.y;
        
        if (diff == 0.0 || _ignoreObserver) return;
        
        if (object == self) {
            // Adjust self scroll offset when scroll down
            if (diff < 0 && _lock) {
                [self scrollView:self setContentOffset:old];
            }
            // Scroll up or the collection view don't need lock.
            else if (self.contentOffset.y < -self.contentInset.top && !self.bounces) {
                [self scrollView:self setContentOffset:CGPointMake(self.contentOffset.x, -self.contentInset.top)];
            }
            // Sticky on the top.
            else if (self.contentOffset.y > self.bindingScrollPosition) {
                [self scrollView:self setContentOffset:CGPointMake(self.contentOffset.x, self.bindingScrollPosition)];
            }
            
        } else {
            // Adjust the observed scrollview's content offset
            UIScrollView *scrollView = object;
            _lock = (scrollView.contentOffset.y > -scrollView.contentInset.top);
            
            // Manage scroll up
            if (self.contentOffset.y < self.bindingScrollPosition && _lock && diff > 0) {
                [self scrollView:scrollView setContentOffset:old];
            }
            // Disable bouncing when scroll down
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
    _ignoreObserver = YES;
    scrollView.contentOffset = offset;
    _ignoreObserver = NO;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:kHBContentOffsetContext];
    [self removeObservedViews];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _lock = NO;
    [self removeObservedViews];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self scrollViewDidEndDecelerating:scrollView];
    }
}

@end




@implementation HBHybridCollectionViewProxy

#pragma mark - Scroll Delegate Methods Overrides

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

- (void)collectionView:(HBHybridCollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([collectionView.delegate respondsToSelector:@selector(sectionForBindingScrollInCollectionView:)]) {
        NSInteger section = [collectionView.delegate sectionForBindingScrollInCollectionView:collectionView];
        
        if (indexPath.section == section) {
            collectionView.bindingScrollPosition = CGRectGetMinY(cell.frame);
        }
    }
    
    if ([_delegate respondsToSelector:_cmd]) {
        [_delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
}

#pragma mark - Forwarding Messages

- (BOOL)respondsToSelector:(SEL)selector {
    return [self.delegate respondsToSelector:selector] || [super respondsToSelector:selector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    // Keep it lightweight: access the ivar directly
    return _delegate;
}

// handling unimplemented methods and nil target/interceptor
// https://github.com/Flipboard/FLAnimatedImage/blob/76a31aefc645cc09463a62d42c02954a30434d7d/FLAnimatedImage/FLAnimatedImage.m#L786-L807
- (void)forwardInvocation:(NSInvocation *)invocation {
    // Fallback for when target is nil. Don't do anything, just return 0/NULL/nil.
    // The method signature we've received to get here is just a dummy to keep `doesNotRecognizeSelector:` from firing.
    // We can't really handle struct return types here because we don't know the length.
    void *nullPointer = NULL;
    [invocation setReturnValue:&nullPointer];
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    // We only get here if `forwardingTargetForSelector:` returns nil.
    // In that case, our weak target has been reclaimed. Return a dummy method signature to keep `doesNotRecognizeSelector:` from firing.
    // We'll emulate the Obj-c messaging nil behavior by setting the return value to nil in `forwardInvocation:`, but we'll assume that the return value is `sizeof(void *)`.
    // Other libraries handle this situation by making use of a global method signature cache, but that seems heavier than necessary and has issues as well.
    // See https://www.mikeash.com/pyblog/friday-qa-2010-02-26-futures.html and https://github.com/steipete/PSTDelegateProxy/issues/1 for examples of using a method signature cache.
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

@end

