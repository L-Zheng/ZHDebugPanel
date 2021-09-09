//
//  ZHDPListMemory.m
//  ZHJSNative
//
//  Created by EM on 2021/6/16.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListMemory.h"
#import "ZHDPManager.h"// 调试面板管理

@implementation ZHDPListMemory

#pragma mark - data

- (NSArray <ZHDPListSecItem *> *)fetchAllItems{
    return [ZHDPMg() fetchAllAppDataItems:self.class];
}

#pragma mark - reload

- (void)reloadListWhenSelectApp{
    [ZHDPMg() zh_test_reloadMemory];
    [super reloadListWhenShow];
}
- (void)reloadListWhenSearch{
    [super reloadListWhenShow];
}
- (void)reloadListWhenCloseSearch{
    [super reloadListWhenShow];
}
- (void)reloadListWhenRefresh{
    [ZHDPMg() zh_test_reloadMemory];
    [super reloadListWhenShow];
}
- (void)reloadListWhenShow{
//    NSArray <ZHDPListSecItem *> *items = [self fetchAllItems]?:@[];
//    if (items.count == 0) {
        [ZHDPMg() zh_test_reloadMemory];
//    }
    [super reloadListWhenShow];
}
#pragma mark - delete store

- (void)deleteStore:(NSArray <ZHDPListSecItem *> *)secItems{
//    for (ZHDPListSecItem *secItem in secItems) {
//        @autoreleasepool {
//            if (secItem.rowItems.count == 0 ||  secItem.rowItems.firstObject.colItems.count == 0) {
//                continue;
//            }
//            NSString *key =  secItem.rowItems.firstObject.colItems.firstObject.attTitle.string;
//            [[ZHMemoryManager shareManager] removeMemorySync:@{@"key": key?:@""} appId:nil extraInfo:nil];
//        }
//    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    // 删除
    [self deleteStore:@[self.items[indexPath.section]]];
    
    [super tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
}



@end
