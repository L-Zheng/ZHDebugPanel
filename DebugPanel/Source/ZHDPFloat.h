//
//  ZHDPFloat.h
//  ZHJSNative
//
//  Created by EM on 2021/5/31.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZHDPDataTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPFloat : UIView
@property (nonatomic,copy) void (^tapBlock) (void);
@property (nonatomic,copy) void (^doubleTapBlock) (void);

- (void)updateTitle:(NSString *)title;
- (void)showTip:(NSString *)title animateCount:(float)animateCount outputType:(ZHDPOutputType)outputType clickBlock:(void (^) (void))clickBlock;
@property (nonatomic,copy) void (^ __nullable clickErrorBlock) (void);

- (void)stopAnimation;

@end

NS_ASSUME_NONNULL_END
