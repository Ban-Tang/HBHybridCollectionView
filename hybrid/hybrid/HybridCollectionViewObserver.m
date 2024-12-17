//
//  HybridCollectionViewObserver.m
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 BanTang. All rights reserved.
//

#import "HybridCollectionViewObserver.h"
#import <objc/runtime.h>

@interface HybridCollectionViewObserver ()

@property (nonatomic, unsafe_unretained) id unsafeTarget;
@property (nonatomic, strong) NSString *keyPath;
@property (nonatomic, weak) id interceptor;

@end

@implementation HybridCollectionViewObserver

- (void)dealloc {
    NSObject *target;
    @synchronized (self) {
        target = _unsafeTarget;
        _unsafeTarget = nil;
    }
    [target removeObserver:self forKeyPath:_keyPath];
}

- (instancetype)initWithTarget:(id)target keyPath:(NSString *)keyPath interceptor:(id)interceptor {
    self = [super init];
    if (self) {
        _unsafeTarget = target;
        _keyPath = keyPath;
        _interceptor = interceptor;
        [target addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NSSelectorFromString(keyPath)];
    }
    return self;
}

+ (void)addObserver:(id)object withTarget:(id)target keyPath:(NSString *)keyPath {
    if (target == nil || object == nil) {
        return;
    }
    void *key = NSSelectorFromString([NSString stringWithFormat:@"%p_%@", object, keyPath]);
    
    HybridCollectionViewObserver *observer = objc_getAssociatedObject(target, key);
    if (observer) {
        return;
    }
    observer = [[HybridCollectionViewObserver alloc] initWithTarget:target keyPath:keyPath interceptor:object];
    // Add reference for auto dealloc. do not deal with interceptor now, which means
    // when the interceptor dealloc the observer will still be alive with the target.
    objc_setAssociatedObject(target, key, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)removeObserver:(id)object withTarget:(id)target keyPath:(NSString *)keyPath {
    if (target == nil) {
        return;
    }
    void *key = NSSelectorFromString([NSString stringWithFormat:@"%p_%@", object, keyPath]);
    objc_setAssociatedObject(target, key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([_interceptor respondsToSelector:_cmd]) {
        [_interceptor observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
