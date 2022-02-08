//
//  UIViewController+ZHDPLeak.h
//  ZHDebugPanel
//
//  Created by EM on 2022/2/8.
//

#import <UIKit/UIKit.h>

@interface UIViewController (ZHDPLeak)
@property (nonatomic, copy) void (^zhdp_leak_viewDidDisappear) (void);
@end
