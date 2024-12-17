//
//  HybridCollectionViewProxy.m
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 BanTang. All rights reserved.
//

#import "HybridCollectionViewProxy.h"

@interface HybridCollectionViewProxy () {
    __weak id _interceptor;
}
@end

@implementation HybridCollectionViewProxy

- (instancetype)initWithTarget:(id)target interceptor:(id)interceptor {
    if (self = [super init]) {
        _target = target;
        _interceptor = interceptor;
    }
    return self;
}

- (Class)superclass {
    return [_target superclass];
}

- (Class)class {
    return [_target class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
    return YES;
}

#pragma mark - Forwarding Messages

- (BOOL)respondsToSelector:(SEL)selector {
    return [_interceptor respondsToSelector:selector]
    || [_target respondsToSelector:selector]
    || [super respondsToSelector:selector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    // Keep it lightweight: access the ivar directly
    if ([_interceptor respondsToSelector:selector]) {
        return _interceptor;
    }
    return _target;
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
