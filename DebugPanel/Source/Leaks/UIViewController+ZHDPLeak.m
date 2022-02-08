//
//  UIViewController+ZHDPLeak.m
//  ZHDebugPanel
//
//  Created by EM on 2022/2/8.
//

#import "UIViewController+ZHDPLeak.h"
#import <objc/runtime.h>

@implementation UIViewController (ZHDPLeak)

- (void (^)(void))zhdp_leak_viewDidDisappear{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setZhdp_leak_viewDidDisappear:(void (^)(void))zhdp_leak_viewDidDisappear{
    objc_setAssociatedObject(self, @selector(zhdp_leak_viewDidDisappear), zhdp_leak_viewDidDisappear, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end
