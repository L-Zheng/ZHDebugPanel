//
//  ZHDPListCrash.m
//  ZHDebugPanel
//
//  Created by EM on 2022/2/11.
//

#import "ZHDPListCrash.h"
#import "ZHDPManager.h"// 调试面板管理

@implementation ZHDPListCrash

#pragma mark - data

- (NSArray <ZHDPListSecItem *> *)fetchAllItems{
    return [ZHDPMg() fetchAllAppDataItems:self.class];
}

#pragma mark - filter

- (void)enableAutoFilterWhenCliDebug{
}

#pragma mark - delete store

- (void)deleteStore:(NSArray <ZHDPListSecItem *> *)secItems{
}
- (void)execAutoDeleteList{
}
- (BOOL)allowAutoDeleteList{
    return NO;
}

@end
