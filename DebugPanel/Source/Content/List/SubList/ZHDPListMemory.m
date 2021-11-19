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
    [super reloadListClear];
    [ZHDPMg() zh_test_reloadMemory];
}
- (void)reloadListWhenSearch{
    [super reloadListWhenShow];
}
- (void)reloadListWhenCloseSearch{
    [super reloadListWhenShow];
}
- (void)reloadListWhenRefresh{
    [super reloadListClear];
    [ZHDPMg() zh_test_reloadMemory];
}
- (void)reloadListWhenShow{
    [super reloadListClear];
//    NSArray <ZHDPListSecItem *> *items = [self fetchAllItems]?:@[];
//    if (items.count == 0) {
        [ZHDPMg() zh_test_reloadMemory];
//    }
}

#pragma mark - scroll

- (BOOL)scrollAnimated{
    return YES;
}

#pragma mark - delete store

- (void)deleteStore:(NSArray <ZHDPListSecItem *> *)secItems{
//    [ZHDPMg() fw_test_deleteMemoryStore:secItems];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    // 删除
    [self deleteStore:@[self.items[indexPath.section]]];
    
    [super tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
}



@end
