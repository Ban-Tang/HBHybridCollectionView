//
//  RLHybridCollectionView.m
//  hybrid
//
//  Created by roylee on 2017/11/22.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import "HBHybridCollectionView.h"
#import <objc/runtime.h>

@interface HBHybridCollectionViewObserver : NSObject
@property (nonatomic, unsafe_unretained) id unsafeTarget;
@property (nonatomic, strong) NSString *keyPath;
@property (nonatomic, weak) id interceptor;
@end

static void *const kHBContentOffsetContext = (void*)&kHBContentOffsetContext;

@implementation HBHybridCollectionViewObserver

- (instancetype)initWithTarget:(id)target keyPath:(NSString *)keyPath interceptor:(id)interceptor {
    self = [super init];
    if (self) {
        _unsafeTarget = target;
        _keyPath = keyPath;
        _interceptor = interceptor;
        
        [target addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:kHBContentOffsetContext];
    }
    return self;
}

- (void)dealloc {
    NSObject *target;
    @synchronized (self) {
        target = _unsafeTarget;
        _unsafeTarget = nil;
    }
    [target removeObserver:self forKeyPath:_keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([_interceptor respondsToSelector:_cmd]) {
        [_interceptor observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end




@interface HBHybridCollectionViewProxy : NSObject <HBHybridCollectionViewDelegate> {
    __weak id _delegate;
}
- (instancetype)initWithDelegate:(id)delegate;
@end




@interface HBHybridCollectionView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) HBHybridCollectionViewProxy *forwarder;
@property (nonatomic, assign) CGFloat bindingScrollPosition;

@end



@implementation HBHybridCollectionView {
    BOOL _ignoreObserver;
    BOOL _lock; //!< lock the collection view when scrolling.
}

@synthesize delegate = _delegate;

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
    
    self.bindingScrollPosition = CGFLOAT_MAX;
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))
              options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
              context:kHBContentOffsetContext];
}

#pragma mark - Properties

- (void)setDelegate:(id<HBHybridCollectionViewDelegate>)delegate {
    // Scroll view delegate caches whether the delegate responds to some of the delegate
    // methods, so we need to force it to re-evaluate if the delegate responds to them
    super.delegate = nil;
    
    self.forwarder = nil;
    if (!delegate) return;
    
    self.forwarder = [[HBHybridCollectionViewProxy alloc] initWithDelegate:delegate];
    super.delegate = self.forwarder;
}

- (id<HBHybridCollectionViewDelegate>)delegate {
    return (id<HBHybridCollectionViewDelegate>)super.delegate;
}

- (BOOL)isSticky {
    return self.contentOffset.y >= _bindingScrollPosition;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.view != self) {
        return NO;
    }
    if ([self.delegate respondsToSelector:@selector(collectionView:touchShouldBeganAtPoint:)]) {
        [self.delegate collectionView:self touchShouldBeganAtPoint:[gestureRecognizer locationInView:self]];
    }
    return [super gestureRecognizerShouldBegin:gestureRecognizer];
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
    
    // Tricky case: UITableViewWrapperView
    if ([scrollView.superview isKindOfClass:[UITableView class]]) {
        return NO;
    }
    
    BOOL shouldScroll = YES;
    if ([self.delegate respondsToSelector:@selector(collectionView:shouldScrollWithSubView:)]) {
        shouldScroll = [self.delegate collectionView:self shouldScrollWithSubView:scrollView];;
    }
    
    if (shouldScroll) {
        [self addObserverToView:scrollView];
    }
    
    return shouldScroll;
}

#pragma mark KVO

static char HBObserverAssociatedKey;

- (void)addObserverToView:(UIScrollView *)scrollView {
    _lock = (scrollView.contentOffset.y > -scrollView.contentInset.top);
    
    HBHybridCollectionViewObserver *observer = [[HBHybridCollectionViewObserver alloc] initWithTarget:scrollView keyPath:NSStringFromSelector(@selector(contentOffset)) interceptor:self];
    objc_setAssociatedObject(scrollView, &HBObserverAssociatedKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)removeObserverFromView:(UIScrollView *)scrollView {
    objc_setAssociatedObject(scrollView, &HBObserverAssociatedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

- (void)scrollView:(UIScrollView *)scrollView setContentOffset:(CGPoint)offset {
    _ignoreObserver = YES;
    scrollView.contentOffset = offset;
    _ignoreObserver = NO;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:kHBContentOffsetContext];
}

@end




@implementation HBHybridCollectionViewProxy

- (instancetype)initWithDelegate:(id)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Scroll Delegate Methods Overrides

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
    return [_delegate respondsToSelector:selector] || [super respondsToSelector:selector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    // Keep it lightweight: access the ivar directly
    if ([_delegate respondsToSelector:selector]) {
        return _delegate;
    }
    return [super forwardingTargetForSelector:selector];
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

