//
//  ZHDPList.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
@class ZHDPListItem;// list数据
@class ZHDPListSecItem;// 每一组数据
@class ZHDPDataSpaceItem;// 数据存储容量

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPList : ZHDPComponent <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) ZHDPListItem *item;

@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *items;
@property (nonatomic,copy) void (^reloadListBlock) (NSArray <ZHDPListSecItem *> *items);
@property (nonatomic,strong) UITableView *tableView;

#pragma mark - search

- (void)showSearch;
- (BOOL)isShowSearch;
- (void)hideSearch;
- (void)resignFirstResponder;
- (BOOL)isFirstResponder;

#pragma mark - sub class

- (NSArray <ZHDPListSecItem *> *)fetchAllItems;
- (NSString *)footerTipTitle;

#pragma mark - reload

- (void)addSecItem:(ZHDPListSecItem *)item spaceItem:(ZHDPDataSpaceItem *)spaceItem;
- (void)removeSecItems:(NSArray <ZHDPListSecItem *> *)secItems instant:(BOOL)instant;
//- (void)removeSecItem:(ZHDPListSecItem *)secItem;
//- (void)clearSecItems;
- (void)reloadListClear;
- (void)reloadListWhenShow;
- (void)reloadList;
- (void)scrollListToBottomCode;
- (void)scrollListToTopCode;

#pragma mark - filter

- (void)enableAutoFilterWhenCliDebug;
- (void)filterByCode:(NSString *)appId;

#pragma mark - delete

- (void)execAutoDeleteList;
- (BOOL)allowAutoDeleteList;

@end

NS_ASSUME_NONNULL_END
