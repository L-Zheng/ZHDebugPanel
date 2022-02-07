//
//  UIViewController+ZHLeak.m
//  ZHDebugPanel
//
//  Created by Zheng on 2022/2/7.
//

#import "UIViewController+ZHLeak.h"
#import <objc/runtime.h>

@implementation UIViewController (ZHLeak)

- (void (^)(void))zh_leak_viewDidDisappear{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setZh_leak_viewDidDisappear:(void (^)(void))zh_leak_viewDidDisappear{
    objc_setAssociatedObject(self, @selector(zh_leak_viewDidDisappear), zh_leak_viewDidDisappear, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
