//
//  ZHDPListNetwork.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListNetwork.h"
#import "ZHDPManager.h"// 调试面板管理

@implementation ZHDPListNetwork

#pragma mark - data

- (NSArray <ZHDPListSecItem *> *)fetchAllItems{
    return [ZHDPMg() fetchAllAppDataItems:self.class];
}

#pragma mark - filter

- (void)enableAutoFilterWhenCliDebug{
    [super enableAutoFilterWhenCliDebug];
}

#pragma mark - delete store

- (void)deleteStore:(NSArray <ZHDPListSecItem *> *)secItems{
}
- (void)enableAutoDeleteWhenCliDebug{
    [super enableAutoDeleteWhenCliDebug];
}
- (void)execAutoDeleteList{
    [super execAutoDeleteList];
}
- (BOOL)allowAutoDeleteList{
    return YES;
}

@end
