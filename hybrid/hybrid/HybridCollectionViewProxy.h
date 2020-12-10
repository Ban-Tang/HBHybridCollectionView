//
//  HybridCollectionViewProxy.h
//  hybrid
//
//  Created by roylee on 2020/12/9.
//  Copyright © 2020 bantang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
A weak proxy for methods intercept.
*/
@interface HybridCollectionViewProxy : NSObject

@property (nonatomic, weak, readonly) id target;

/**
 Create a new proxy object with target and interceptor.
 
 @param target      An object that receives non-intercepted messages.
 @param interceptor An object that intercepts a set of messages.
 @return            A new JTProxy object.
 */
- (instancetype)initWithTarget:(id)target
                   interceptor:(nullable id)interceptor;

/**
 :nodoc:
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 :nodoc:
 */
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
