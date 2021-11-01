//
//  ZHDPFloat.h
//  ZHJSNative
//
//  Created by EM on 2021/5/31.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPFloat : UIView
@property (nonatomic,copy) void (^tapBlock) (void);
@property (nonatomic,copy) void (^doubleTapBlock) (void);

- (void)updateTitle:(NSString *)title;
- (void)showErrorTip:(NSString *)title clickBlock:(void (^) (void))clickBlock;
@property (nonatomic,copy) void (^ __nullable clickErrorBlock) (void);
@end

NS_ASSUME_NONNULL_END
