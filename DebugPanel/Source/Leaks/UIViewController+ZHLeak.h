//
//  UIViewController+ZHLeak.h
//  ZHDebugPanel
//
//  Created by Zheng on 2022/2/7.
//

#import <UIKit/UIKit.h>

@interface UIViewController (ZHLeak)
@property (nonatomic, copy) void (^zh_leak_viewDidDisappear) (void);
@end
