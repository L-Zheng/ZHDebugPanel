//
//  ZHDPDataTask.m
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPDataTask.h"
#import "ZHDPStorageManager.h"
#import "ZHDPManager.h"

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
- (NSMutableArray *)fetchDataItems:(Class)cls{
    return [self.dataItemsMap objectForKey:cls];
}
@end


// 数据管理
@implementation ZHDPDataTask
- (ZHDPDataSpaceItem *)fetchSpaceItem:(Class)cls{
    return [self.spaceItemMap objectForKey:cls];
}
- (NSArray <ZHDPDataSpaceItem *> *)fetchSpaceItems{
    return [self.spaceItemMap allValues];
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
        
        // 初始化数据用于存储日志
        NSMutableDictionary *dataItemsMap = [NSMutableDictionary dictionary];
        NSArray *configs = [self.dpManager fetchListConfig];
        for (NSArray *config in configs) {
            [dataItemsMap setObject:[NSMutableArray array] forKey:config[1]];
        }
        item.dataItemsMap = dataItemsMap.copy;
        
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
