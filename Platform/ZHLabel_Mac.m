//
//  ZHLabel_Mac.m
//  ZHDebugPanel
//
//  Created by EM on 2021/6/25.
//

#import "ZHLabel_Mac.h"

#if ZH_TARGET_OS_MAC

@implementation ZHLabel_Mac

- (instancetype)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        self.editable = NO;
    }
    return self;
}

@end

#endif
