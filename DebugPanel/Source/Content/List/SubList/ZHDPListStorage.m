//
//  ZHDPListStorage.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListStorage.h"
#import "ZHDPManager.h"// 调试面板管理

@implementation ZHDPListStorage

#pragma mark - data

- (NSArray <ZHDPListSecItem *> *)fetchAllItems{
    return [ZHDPMg() fetchAllAppDataItems:self.class];
}

#pragma mark - reload

- (void)reloadListWhenSelectApp{
    [ZHDPMg() zh_test_reloadStorage];
    [super reloadListWhenShow];
}
- (void)reloadListWhenSearch{
    [super reloadListWhenShow];
}
- (void)reloadListWhenCloseSearch{
    [super reloadListWhenShow];
}
- (void)reloadListWhenRefresh{
    [ZHDPMg() zh_test_reloadStorage];
    [super reloadListWhenShow];
}
- (void)reloadListWhenShow{
//    NSArray <ZHDPListSecItem *> *items = [self fetchAllItems]?:@[];
//    if (items.count == 0) {
        [ZHDPMg() zh_test_reloadStorage];
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
//            ZHDPListColItem *colItem = secItem.rowItems.firstObject.colItems.firstObject;
//            NSString *key = colItem.attTitle.string;
//            NSMutableDictionary *res = @{@"key":((key && [key isKindOfClass:NSString.class] && key.length) ? key : @"")}.mutableCopy;
//            [res addEntriesFromDictionary:@{
//                @"level": colItem.extraInfo[@"level"]?:@"",
//                @"prefix": colItem.extraInfo[@"prefix"]?:@""
//            }];
//            [[ZHStorageManager shareInstance] removeStorageSync:res.copy appId:colItem.extraInfo[@"appId"]?:@""];
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
