//
//  HybridCollectionViewObserver.h
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 BanTang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Easy use weak KVO observer.

 @note the KVO call back method is same as `-observeValueForKeyPath:ofObject:change:context:`
 */
@interface HybridCollectionViewObserver : NSObject

- (instancetype)initWithTarget:(id)target
                       keyPath:(NSString *)keyPath
                   interceptor:(id)interceptor;

+ (void)addObserver:(id)observer withTarget:(id)target keyPath:(NSString *)keyPath;

+ (void)removeObserver:(id)observer withTarget:(id)target keyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
