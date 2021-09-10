//
//  ZHDPContent.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
@class ZHDPListSecItem;// 数据
@class ZHDPList;// 列表

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPContent : ZHDPComponent
- (NSArray <ZHDPList *> *)fetchAllLists;
@property (nonatomic, strong) ZHDPList *selectList;
- (void)selectList:(ZHDPList *)list;
@property (nonatomic,copy) void (^reloadListBlock) (ZHDPList *list, NSArray <ZHDPListSecItem *> * items);
@end

NS_ASSUME_NONNULL_END
