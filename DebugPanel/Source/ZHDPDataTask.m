//
//  ZHDPDataTask.m
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPDataTask.h"

// list操作栏数据
@implementation ZHDPListToolItem
@end

// 描述list的信息
@implementation ZHDPListItem
+ (instancetype)itemWithTitle:(NSString *)title{
    ZHDPListItem *item = [[ZHDPListItem alloc] init];
    item.title = title;
    return item;
}
+ (CGFloat)maxHeightByColItems:(NSArray<ZHDPListColItem *> *)colItems{
    CGFloat res = 0;
    for (ZHDPListColItem *colItem in colItems) {
        CGFloat h = colItem.rectValue.CGRectValue.size.height;
        if (res < h) res = h;
    }
    return res;
}
@end

// 某条日志的输出类型
@implementation ZHDPOutputItem
+ (NSDictionary *)outputMap{
    return @{
        @(ZHDPOutputType_Log): @{
                @"color": @"#000000",
                @"desc": @"log"
        },
        @(ZHDPOutputType_Info): @{
                @"color": @"#000000",
                @"desc": @"info"
        },
        @(ZHDPOutputType_Debug): @{
                @"color": @"#000000",
                @"desc": @"debug"
        },
        @(ZHDPOutputType_Warning): @{
                @"color": @"#FFD700",
                @"desc": @"warning"
        },
        @(ZHDPOutputType_Error): @{
                @"color": @"#DC143C",
                @"desc": @"error"
        }
    };
}
+ (NSArray <ZHDPOutputItem *> *)allItems{
    NSMutableArray *arr = [NSMutableArray array];
    NSArray *types = [self outputMap].allKeys;
    for (NSNumber *typeNum in types) {
        ZHDPOutputItem *item = [[ZHDPOutputItem alloc] init];
        item.type = typeNum.integerValue;
        [arr addObject:item];
    }
    return arr.copy;
}
+ (NSString *)colorStrByType:(ZHDPOutputType)type{
    return [[[self outputMap] objectForKey:@(type)] objectForKey:@"color"];
}
- (NSString *)colorStr{
    return [self.class colorStrByType:self.type]?:@"#000000";
}
- (NSString *)desc{
    return [[[self.class outputMap] objectForKey:@(self.type)] objectForKey:@"desc"];
}
@end

// 某条日志的简要信息
@implementation ZHDPFilterItem
@end

@implementation ZHDPFilterListItem
@end

// list中每一行中每一分段的信息
@implementation ZHDPListColItem
@end

// list中每一行的信息
@implementation ZHDPListRowItem
- (void)setColItems:(NSArray<ZHDPListColItem *> *)colItems{
    _colItems = colItems.copy;
    self.rowH = [ZHDPListItem maxHeightByColItems:_colItems];
}
@end

// list选中某一组显示的详细信息
@implementation ZHDPListDetailItem
@end

// list中每一组的信息
@implementation ZHDPListSecItem
- (void)setColItems:(NSArray<ZHDPListColItem *> *)colItems{
    _colItems = colItems.copy;
    self.headerH = [ZHDPListItem maxHeightByColItems:_colItems];
}
@end

// 某种类型数据的存储最大容量
@implementation ZHDPDataSpaceItem
@end

// list收集量数据
@implementation ZHDPListSpaceItem
@end

// 单个应用的简要信息
@implementation ZHDPAppItem
- (void)setAppId:(NSString *)appId{
    _appId = appId;
    if (appId && [appId isKindOfClass:NSString.class] && appId.length > 0) {
        if ([appId isEqualToString:@"a_socket"]) {
            self.fundCli = YES;
        }
    }
}
@end

// 单个应用的数据
@implementation ZHDPAppDataItem
- (NSMutableArray<ZHDPListSecItem *> *)logItems{
    if (!_logItems) _logItems = [NSMutableArray array];
    return _logItems;
}
- (NSMutableArray<ZHDPListSecItem *> *)networkItems{
    if (!_networkItems) _networkItems = [NSMutableArray array];
    return _networkItems;
}
- (NSMutableArray<ZHDPListSecItem *> *)storageItems{
    if (!_storageItems) _storageItems = [NSMutableArray array];
    return _storageItems;
}
- (NSMutableArray<ZHDPListSecItem *> *)leaksItems{
    if (!_leaksItems) _leaksItems = [NSMutableArray array];
    return _leaksItems;
}
@end


// 数据管理
@implementation ZHDPDataTask
- (NSArray *)spaceItems{
    NSArray *titles = @[@"Log", @"Network", @"Storage", @"Leaks"];
    NSArray <ZHDPDataSpaceItem *> *spaces = @[self.logSpaceItem, self.networkSpaceItem, self.storageSpaceItem, self.leaksSpaceItem];
    
    NSMutableArray *res = [NSMutableArray array];
    for (NSUInteger i = 0; i < titles.count; i++) {
        ZHDPListSpaceItem *spaceItem = [[ZHDPListSpaceItem alloc] init];
        spaceItem.title = titles[i];
        spaceItem.dataSpaceItem = spaces[i];
        spaceItem.count = spaceItem.dataSpaceItem.count;
        
        NSMutableArray *canSelectValues = [NSMutableArray array];
        for (NSInteger j = -10; j < 20; j++) {
            NSInteger value = spaceItem.dataSpaceItem.count + j * 50;
            if (value > 0) {
                [canSelectValues addObject:@(value)];
            }
        }
        spaceItem.canSelectValues = canSelectValues.copy;
        __weak __typeof__(spaceItem) weakSpaceItem = spaceItem;
        spaceItem.block = ^(NSInteger count) {
            weakSpaceItem.dataSpaceItem.count = count;
        };
        [res addObject:spaceItem];
    }
    return res.copy;
}
- (ZHDPDataSpaceItem *)logSpaceItem{
    if (!_logSpaceItem) {
        _logSpaceItem = [self createSpaceItem:100 removePercent:0.5];
    }
    return _logSpaceItem;
}
- (ZHDPDataSpaceItem *)networkSpaceItem{
    if (!_networkSpaceItem) {
        _networkSpaceItem = [self createSpaceItem:100 removePercent:0.5];
    }
    return _networkSpaceItem;
}
- (ZHDPDataSpaceItem *)storageSpaceItem{
    if (!_storageSpaceItem) {
        _storageSpaceItem = [self createSpaceItem:100 removePercent:0.5];
    }
    return _storageSpaceItem;
}
- (ZHDPDataSpaceItem *)leaksSpaceItem{
    if (!_leaksSpaceItem) {
        _leaksSpaceItem = [self createSpaceItem:100 removePercent:0.5];
    }
    return _leaksSpaceItem;
}
- (ZHDPDataSpaceItem *)createSpaceItem:(NSUInteger)count removePercent:(CGFloat)removePercent{
    ZHDPDataSpaceItem *item = [[ZHDPDataSpaceItem alloc] init];
    item.count = (count > 0 ? count : 20);
    item.removePercent = (removePercent <= 0 ? 0.5 : (removePercent >= 1.0 ? 1.0 : removePercent));
    return item;
}

// 查找所有应用的数据
- (NSArray <ZHDPAppDataItem *> *)fetchAllAppDataItems{
    return [self.appDataMap allValues].copy;
}

// 查找某个应用的数据
- (ZHDPAppDataItem *)fetchAppDataItem:(ZHDPAppItem *)appItem{
    NSString *appId = appItem.appId;
    if (!appId || ![appId isKindOfClass:NSString.class] || appId.length == 0) {
        return nil;
    }
    ZHDPAppDataItem *item = [self.appDataMap objectForKey:appId];
    if (!item) {
        item = [[ZHDPAppDataItem alloc] init];
        item.appItem = appItem;
        [self.appDataMap setObject:item forKey:appId];
    }
    return item;
}


- (void)cleanAllAppDataItems{
    [self.appDataMap removeAllObjects];
}
// 清理并添加数据
- (void)cleanAllItems:(NSMutableArray *)items{
    [items removeAllObjects];
}
- (void)cleanItems:(NSMutableArray *)items spaceItem:(ZHDPDataSpaceItem *)spaceItem{
    if (!items) return;
    
    CGFloat limit = spaceItem.count;
    CGFloat removePercent = spaceItem.removePercent;
    
    if (items.count <= limit) return;
    
    NSInteger removeCount = floorf(items.count * removePercent);
    if (removeCount < 0) removeCount = 0;
    
    if (removeCount >= items.count) return;
    
    [items removeObjectsInRange:NSMakeRange(0, removeCount)];
}
- (void)addItem:(NSMutableArray *)items item:(ZHDPListSecItem *)item{
    if (!items || !item) return;
    [items addObject:item];
}
- (void)addAndCleanItems:(NSMutableArray *)items item:(ZHDPListSecItem *)item spaceItem:(ZHDPDataSpaceItem *)spaceItem{
    [self addItem:items item:item];
    [self cleanItems:items spaceItem:spaceItem];
}

// 映射表
- (NSMutableDictionary *)appDataMap{
    if (!_appDataMap) {
        _appDataMap = [NSMutableDictionary dictionary];
    }
    return _appDataMap;
}

@end
