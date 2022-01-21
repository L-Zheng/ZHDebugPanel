//
//  ZHDPList.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPList.h"
#import "ZHDPListCell.h"// list cell
#import "ZHDPListHeader.h"// list header
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPListOprate.h"// pop操作栏
#import "ZHDPListSearch.h"// 搜索
#import "ZHDPListApps.h"// pop app列表
#import "ZHDPListDetail.h"// pop detail数据
#import "ZHDPListOption.h"// 工具栏
#import "ZHDPListSpace.h"// 收集量

typedef NS_ENUM(NSInteger, ZHDPScrollStatus) {
    ZHDPScrollStatus_Idle      = 0,//闲置
    ZHDPScrollStatus_Dragging      = 1,//拖拽中
    ZHDPScrollStatus_DraggingDecelerate      = 2,//拖拽后减速
};

@interface ZHDPList ()

@property (nonatomic,retain) NSMutableArray *items_temp;
@property (nonatomic,retain) NSMutableArray *removeItems_temp;

@property (nonatomic,assign) ZHDPScrollStatus scrollStatus;
@property (nonatomic,assign) BOOL allowScrollAuto;

@property (nonatomic,strong) ZHDPListSearch *search;
@property (nonatomic,assign) CGFloat searchH;

@property (nonatomic,strong) ZHDPListOprate *oprate;
@property (nonatomic,strong) ZHDPListApps *apps;
@property (nonatomic,strong) ZHDPListDetail *detail;
@property (nonatomic,strong) ZHDPListOption *option;
@property (nonatomic,strong) ZHDPListSpace *space;

@property (nonatomic,strong) UILabel *tipLabel;

@property (nonatomic,assign) BOOL autoDeleteEnable;

@property (nonatomic,assign) BOOL hasEnableAutoFilterWhenCliDebug;

@end

@implementation ZHDPList

#pragma mark - override

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configData];
        [self configUI];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];

    [self updateSearchFrame];
    [self.oprate updateFrameH];
    [self.apps updateFrameH];
    [self.detail updateFrameH];
    [self.space updateFrameH];
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
    BOOL show = self.superview;
    if (!show) return;
    [self reloadListWhenShow];
}

#pragma mark - config

- (void)configData{
    self.allowScrollAuto = YES;
    self.searchH = 0;
    [self configAutoDelete:YES];
}
- (void)configUI{
    self.clipsToBounds = YES;
    
    [self addSubview:self.search];
    [self addSubview:self.tableView];
    [self addSubview:self.option];
    
    [self relaodOprate];
    [self relaodOption];
}

#pragma mark - search

- (void)updateSearchFrame{
    CGFloat h = self.searchH;
    self.search.frame = CGRectMake(0, 0, self.bounds.size.width, h);
    CGFloat optionH = 50;
    self.option.frame = CGRectMake(0, self.bounds.size.height - optionH, self.bounds.size.width, optionH);
    self.tableView.frame = CGRectMake(0, h, self.bounds.size.width, self.bounds.size.height - h - optionH);
    self.tableView.tableFooterView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 44);
}
- (BOOL)verifyFilterCondition:(ZHDPListSecItem *)secItem{
    if (!secItem || ![secItem isKindOfClass:ZHDPListSecItem.class]) {
        return NO;
    }
    
    ZHDPFilterItem *filterItem = self.apps.selectItem;
    
    // 筛选appId
    ZHDPAppItem *selectAppItem = filterItem.appItem;
    ZHDPAppItem *cAppItem = secItem.appDataItem.appItem;
    if (selectAppItem && cAppItem) {
        if (![selectAppItem.appId isEqualToString:cAppItem.appId]) {
            return NO;
        }
    }
    
    // 筛选page
    NSString *selectPage = filterItem.page;
    NSString *cPage = secItem.filterItem.page;
    if (selectPage && [selectPage isKindOfClass:NSString.class] && selectPage.length > 0) {
        if (!cPage || ![cPage isKindOfClass:NSString.class] || cPage.length == 0 ||
            ![selectPage isEqualToString:cPage]) {
            return NO;
        }
    }
    
    // 筛选日志类型
    ZHDPOutputType selectType = filterItem.outputItem.type;
    if (selectType != ZHDPOutputType_All &&
        selectType != secItem.filterItem.outputItem.type) {
        return NO;
    }
    
    
    // 筛选搜索关键字
    NSString *keyword = self.search.keyWord;
    if (!keyword || ![keyword isKindOfClass:NSString.class] || keyword.length == 0) {
        return YES;
    }
    // 搜索某一组
    NSArray <ZHDPListColItem *> *colItems = secItem.colItems.copy;
    for (ZHDPListColItem *colItem in colItems) {
        if ([colItem.attTitle.string.lowercaseString containsString:keyword.lowercaseString]) {
            return YES;
        }
    }
    // 搜索某一行
    NSArray <ZHDPListRowItem *> *rowItems = secItem.rowItems.copy;
    for (ZHDPListRowItem *rowItem in rowItems) {
        colItems = rowItem.colItems.copy;
        for (ZHDPListColItem *colItem in colItems) {
            if ([colItem.attTitle.string.lowercaseString containsString:keyword.lowercaseString]) {
                return YES;
            }
        }
    }
    
    return NO;
}
- (NSArray <ZHDPListSecItem *> *)filterItems:(NSArray <ZHDPListSecItem *> *)items{
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return nil;
    }
    
    NSMutableArray <ZHDPListSecItem *> *searchItems = [NSMutableArray array];
    
    NSArray <ZHDPListSecItem *> *newItems = items.copy;
    for (ZHDPListSecItem *secItem in newItems) {
        if (![self verifyFilterCondition:secItem]) continue;
        [searchItems addObject:secItem];
    }
    
    return searchItems.copy;
}
- (void)showSearch{
    if (self.search.frame.size.height > 0) {
        return;
    }
    [ZHDPMg() doAnimation:^{
        self.searchH = 40;
        [self updateSearchFrame];
    } completion:^(BOOL finished) {
        [self.search becomeFirstResponder];
    }];
}
- (BOOL)isShowSearch{
    return (self.searchH > 0);
}
- (void)hideSearch{
    if (self.search.frame.size.height <= 0) {
        return;
    }
    [self.search resignFirstResponder];
    self.searchH = 0;
    [ZHDPMg() doAnimation:^{
        [self updateSearchFrame];
    } completion:^(BOOL finished) {
        [self reloadListWhenCloseSearch];
    }];
}
- (void)resignFirstResponder{
    [self.search resignFirstResponder];
}
- (BOOL)isFirstResponder{
    return [self.search isFirstResponder];
}

#pragma mark - oprate

- (NSArray *)fetchToolItems:(BOOL)isOprate{
    __weak __typeof__(self) weakSelf = self;
    
    NSMutableArray *opItems = @[
        @{
            @"icon": @"\ue68b",
            @"title": @"筛选",
            @"block": ^{
                [weakSelf.apps show];
            }
        },
        @{
            @"icon": @"\ue60b",
            @"title": @"查找",
            @"block": ^{
                [weakSelf.oprate hide];
                [weakSelf showSearch];
            }
        },
        @{
            @"icon": @"\ue636",
            @"title": @"刷新",
            @"block": ^{
                [weakSelf.oprate hide];
                [weakSelf reloadListWhenRefresh];
            }
        },
        @{
            @"icon": @"\ue61d",
            @"title": @"删除",
            @"block": ^{
                [weakSelf.oprate hide];
   //             [ZHDPMg() clearSecItemsList:weakSelf.class appItem:self.apps.selectItem.appItem];
                [weakSelf deleteStore:weakSelf.items.copy];
                [ZHDPMg() removeSecItemsList:weakSelf.class secItems:weakSelf.items.copy instant:NO];
                weakSelf.allowScrollAuto = YES;
            }
        }
    ].mutableCopy;
    if (isOprate && [self allowAutoDeleteList]) {
        [opItems addObject:@{
            @"icon": @"\ue653",
            @"title": @"自动删除",
            @"block": ^{
                [weakSelf configAutoDelete:!weakSelf.autoDeleteEnable];
                [weakSelf relaodOprate];
                [weakSelf relaodOption];
                [ZHDPMg() showToast:[NSString stringWithFormat:@"自动清理-已%@", weakSelf.autoDeleteEnable ? @"开启\n将在页面刷新前清空日志" : @"关闭"] outputType:NSNotFound animateDuration:0.25 stayDuration:2.0 clickBlock:nil showComplete:nil hideComplete:nil];
            }
        }];
    }
    [opItems addObjectsFromArray:@[
        @{
            @"icon": @"\ue630",
            @"title": @"顶部",
            @"block": ^{
                [weakSelf.oprate hide];
                [weakSelf scrollListToTopCode];
            }
        },
        @{
            @"icon": @"\ue691",
            @"title": @"底部",
            @"block": ^{
                [weakSelf.oprate hide];
                [weakSelf scrollListToBottomCode];
            }
        },
        @{
            @"icon": @"\ue608",
            @"title": @"菜单",
            @"block": ^{
                [weakSelf.oprate show];
            }
        },
        @{
            @"icon": @"\ue62d",
            @"title": @"同步到PC",
            @"block": ^{
                if (!0) {
                    [ZHDPMg() showToast:[NSString stringWithFormat:ZHDPToastFundCliUnavailable, @"同步到PC"] outputType:NSNotFound animateDuration:0.25 stayDuration:2.0 clickBlock:nil showComplete:nil hideComplete:nil];
                    [weakSelf.oprate hide];
                    return;
                }
                [weakSelf.oprate hide];
                [ZHDPMg() switchFloat];
            }
        },
        @{
            @"icon": @"\ue60c",
            @"title": @"隐藏",
            @"block": ^{
                [ZHDPMg() switchFloat];
            }
        },
        @{
            @"icon": @"\ue61b",
            @"title": @"沙盒",
            @"block": ^{
                NSString *appSandBox = NSHomeDirectory();
                [[UIPasteboard generalPasteboard] setString:appSandBox];
                [ZHDPMg() showToast:@"已复制-App沙盒地址" outputType:NSNotFound animateDuration:0.25 stayDuration:1.0 clickBlock:nil showComplete:nil hideComplete:nil];
                [weakSelf.oprate hide];
            }
        },
        @{
            @"icon": @"\ue6db",
            @"title": @"收集量",
            @"block": ^{
                [weakSelf.space show];
            }
        },
        @{
            @"icon": @"\ue681",
            @"title": @"退出",
            @"block": ^{
                [ZHDPMg() close];
            }
        }
    ]];
    NSMutableArray <ZHDPListToolItem *> *items = [NSMutableArray array];
    for (NSDictionary *opItem in opItems) {
        ZHDPListToolItem *item = [[ZHDPListToolItem alloc] init];
        item.icon = opItem[@"icon"];
        item.desc = opItem[@"title"];
        item.selected = NO;
        item.block = [opItem[@"block"] copy];
        [items addObject:item];
    }
    
    // 标记过滤
    ZHDPFilterItem *filterItem = self.apps.selectItem;
    if ((filterItem.appItem || (filterItem.outputItem.type != ZHDPOutputType_All)) && items.count > 0) {
        ZHDPListToolItem *item = items.firstObject;
        item.desc = filterItem.appItem.appName?:filterItem.outputItem.desc;
        item.selected = YES;
    }
    
    return items.copy;
}
- (void)relaodOprate{
    NSArray *items = [self fetchToolItems:YES];
    
    // 自动删除
    for (ZHDPListToolItem *item in items) {
        if ([@"自动删除" isEqualToString:item.desc]) {
            item.selected = self.autoDeleteEnable;
            break;
        }
    }
    [self.oprate reloadWithItems:items];
}

#pragma mark - option

- (void)relaodOption{
    NSArray *items = [self fetchToolItems:NO];
    [self.option reloadWithItems:items];
}

#pragma mark - apps

- (void)selectListApps:(ZHDPFilterItem *)item{
    [self relaodOprate];
    [self relaodOption];
    [self.apps hide];
    [self reloadListWhenSelectApp];
}

#pragma mark - sub class

- (NSArray <ZHDPListSecItem *> *)fetchAllItems{
    return nil;
}
- (NSString *)footerTipTitle{
    return @"暂无数据";
}

#pragma mark - reload

- (void)updateSecItemWhenScrollEnd{
    if (self.scrollStatus != ZHDPScrollStatus_Idle) return;
    
    [self addSecItemFrequently];
}
- (void)addSecItemInstant{
    NSArray *arr = self.items_temp.copy;
    if (arr.count <= 0) return;
    
    [self.items_temp removeAllObjects];
    for (void(^block)(void) in arr) {
        block();
    }
    [self reloadList];
}
- (void)addSecItemFrequently:(void (^) (void))block{
    if (!block) return;
    [self.items_temp addObject:block];
    [self addSecItemFrequently];
}
- (void)addSecItemFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(addSecItemInstant) object:nil];
    [self performSelector:@selector(addSecItemInstant) withObject:nil afterDelay:0.25];
}
- (void)addSecItem:(ZHDPListSecItem *)item spaceItem:(ZHDPDataSpaceItem *)spaceItem{
    if (!item || ![item isKindOfClass:ZHDPListSecItem.class]) return;
    
    __weak __typeof__(self) weakSelf = self;
    
    void (^block) (void) = ^(void){
        if ([weakSelf verifyFilterCondition:item]) {
            [ZHDPMg().dataTask addAndCleanItems:weakSelf.items item:item spaceItem:spaceItem];
        }
    };
    if (self.scrollStatus != ZHDPScrollStatus_Idle) {
        [self.items_temp addObject:block];
        return;
    }
    [self addSecItemFrequently:block];
//    block();
//    [self reloadList];
}
- (void)removeSecItems:(NSArray <ZHDPListSecItem *> *)secItems instant:(BOOL)instant{
    if (!secItems || ![secItems isKindOfClass:NSArray.class] || secItems.count == 0 || self.items.count == 0) {
        return;
    }
    [self.removeItems_temp addObjectsFromArray:secItems];
    instant ? [self removeSecItemInstant] : [self removeSecItemFrequently];
}
//- (void)removeSecItem:(ZHDPListSecItem *)secItem{
//    if (!secItem || ![secItem isKindOfClass:ZHDPListSecItem.class] || self.items.count == 0) return;
//    if ([self.items containsObject:secItem]) {
//        [self.removeItems_temp addObject:secItem];
//        [self removeSecItemFrequently];
//    }
//}
//- (void)clearSecItems{
//    if (self.items.count == 0) return;
//    [self.items removeAllObjects];
//    self.allowScrollAuto = YES;
//    [self reloadList];
//}
- (void)removeSecItemFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeSecItemInstant) object:nil];
    [self performSelector:@selector(removeSecItemInstant) withObject:nil afterDelay:0.25];
}
- (void)removeSecItemInstant{
    if (self.removeItems_temp.count == 0) {
        return;
    }
//    NSUInteger originCount = self.items.count;
    [self.items removeObjectsInArray:self.removeItems_temp];
    [self.removeItems_temp removeAllObjects];
//    if (self.items.count == originCount) {
//        return;
//    }
    [self reloadList];
}
- (void)reloadListWhenSelectApp{
    [self reloadListWhenShow];
}
- (void)reloadListWhenSearch{
    [self reloadListWhenShow];
}
- (void)reloadListWhenCloseSearch{
    [self reloadListWhenShow];
}
- (void)reloadListWhenRefresh{
    [self reloadListWhenShow];
}
- (void)reloadListClear{
    self.items = [@[] mutableCopy];
    [self reloadList];
}
- (void)reloadListWhenShow{
    NSArray <ZHDPListSecItem *> *items = [self fetchAllItems]?:@[];
    self.items = [[self filterItems:items.copy]?:@[] mutableCopy];
    [self reloadList];
    [self enableAutoFilterWhenCliDebug];
}
- (void)reloadList{
    self.tableView.tableFooterView = (self.items.count <= 0 ? self.tipLabel : nil);
    
    [self.tableView reloadData];
    if (self.allowScrollAuto) {
        [self scrollListToBottomAuto];
    }
    if (self.reloadListBlock) {
        self.reloadListBlock(self.items.copy);
    }
}

#pragma mark - filter

- (void)enableAutoFilterWhenCliDebug{
    if (1 || self.hasEnableAutoFilterWhenCliDebug) {
        return;
    }
    self.hasEnableAutoFilterWhenCliDebug = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self filterByCode:@"a_socket"];
    });
}
- (void)filterByCode:(NSString *)appId{
    [self.apps selectItemByAppId:appId];
}

#pragma mark - delete store

- (void)deleteStore:(NSArray <ZHDPListSecItem *> *)secItems{
}
- (void)configAutoDelete:(BOOL)enable{
    self.autoDeleteEnable = enable;
}
- (void)execAutoDeleteList{
    if (!self.autoDeleteEnable || ![self allowAutoDeleteList]) return;
    [self.oprate hide];
    
    // 不可直接使用tableView显示的数据self.items进行删除
    // 当调试窗隐藏时，数据不会显示到tableView中因此self.items不准确
//    NSArray *res = self.items.copy;
    NSArray <ZHDPListSecItem *> *items = [self fetchAllItems]?:@[];
    NSMutableArray *res = [[self filterItems:items.copy]?:@[] mutableCopy];
    if (self.items.count > 0) {
        [res addObjectsFromArray:self.items];
    }
    [ZHDPMg() removeSecItemsList:self.class secItems:res.copy instant:NO];
    
    self.allowScrollAuto = YES;
}
- (BOOL)allowAutoDeleteList{
    return YES;
}

#pragma mark - scroll

- (void)updateScrollAuto{
    if (self.scrollStatus != ZHDPScrollStatus_Idle) {
        self.allowScrollAuto = NO;
        return;
    }
    
    CGFloat listH = self.tableView.frame.size.height;
    CGFloat listOffSetY = self.tableView.contentOffset.y;
    CGFloat listContentH = self.tableView.contentSize.height;
    
    if (listContentH <= 0 || listH <= 0) {
        self.allowScrollAuto = YES;
        return;
    }
    if (listContentH <= listH) {
        self.allowScrollAuto = YES;
        return;
    }
    if (listOffSetY >= listContentH - listH - 10) {
        self.allowScrollAuto = YES;
        return;
    }
    self.allowScrollAuto = NO;
}
- (void)scrollListToBottomAuto{
    [self cancelScrollEvent];
    [self performSelector:@selector(scrollListToBottomAutoInternal) withObject:nil afterDelay:0.25];
}
- (void)scrollListToBottomAutoInternal{
    if (!self.allowScrollAuto || self.scrollStatus != ZHDPScrollStatus_Idle) return;
    [self scrollListToBottomInstant];
}
- (void)scrollListToBottomCode{
    [self cancelScrollEvent];
    [self performSelector:@selector(scrollListToBottomInstant) withObject:nil afterDelay:0.25];
}
- (void)scrollListToBottomInstant{
    self.allowScrollAuto = YES;
    
    if (self.items.count <= 0) return;
    
    
    BOOL animated = [self scrollAnimated];
    ZHDPListSecItem *secItem = self.items.lastObject;
    NSInteger rows = (secItem.isOpen ? secItem.rowItems.count : 0);
    NSInteger sec = self.items.count - 1;
    if (rows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:sec] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }else{
        CGFloat listH = self.tableView.frame.size.height;
        CGFloat listContentH = self.tableView.contentSize.height;
        
        if (listContentH <= listH) {
            return;
        }
        // list 总行数为0  不能调用函数scrollToRowAtIndexPath滚动
        [self.tableView setContentOffset:CGPointMake(0, (listContentH - listH)) animated:animated];
    }
}

- (void)scrollListToTopCode{
    [self cancelScrollEvent];
    [self performSelector:@selector(scrollListToTopInstant) withObject:nil afterDelay:0.25];
}
- (void)scrollListToTopInstant{
    if (self.items.count <= 0) return;
    
    
    BOOL animated = [self scrollAnimated];
    ZHDPListSecItem *secItem = self.items.firstObject;
    NSInteger rows = (secItem.isOpen ? secItem.rowItems.count : 0);
    if (rows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }else{
        // list 总行数为0  不能调用函数scrollToRowAtIndexPath滚动
        [self.tableView setContentOffset:CGPointMake(0, 0) animated:animated];
    }
    
    CGFloat listH = self.tableView.frame.size.height;
    CGFloat listContentH = self.tableView.contentSize.height;
    
    if (listContentH <= 0 || listH <= 0) {
        self.allowScrollAuto = YES;
        return;
    }
    if (listContentH <= listH) {
        self.allowScrollAuto = YES;
        return;
    }
    self.allowScrollAuto = NO;
}
- (BOOL)scrollAnimated{
    return YES;
}
- (void)cancelScrollEvent{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollListToBottomAutoInternal) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollListToTopInstant) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollListToBottomInstant) object:nil];
}

#pragma mark - UITableViewDelegate

// 编辑
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除";
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (UITableViewCellEditingStyleDelete == editingStyle) {
        [ZHDPMg() removeSecItemsList:self.class secItems:@[self.items[indexPath.section]] instant:YES];
    }
}

// 存在问题  tableView为多组一行(行高为1像素)模式  调用滚动函数scrollToRowAtIndexPath  有可能滚动不到最底部
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.items.count;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    ZHDPListSecItem *secItem = self.items[section];
    if (secItem.headerH <= 0) {
        return nil;
    }
    ZHDPListHeader *header = [ZHDPListHeader sctionHeaderWithTableView:tableView];
    __weak __typeof__(self) weakSelf = self;
    header.tapGesBlock = ^(BOOL open, ZHDPListSecItem *item) {
        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    [header configItem:secItem];
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    ZHDPListSecItem *secItem = self.items[section];
    return secItem.headerH;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    ZHDPListSecItem *secItem = self.items[section];
    NSInteger rows = secItem.isOpen ? secItem.rowItems.count : 0;
    return rows;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPListSecItem *secItem = self.items[indexPath.section];
    return secItem.rowItems[indexPath.row].rowH;
    // [ZHDPMg() defaultLineW]  返回一个像素的行高  否则  scrollToRowAtIndexPath滚动时  位置可能不准确
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPListSecItem *secItem = self.items[indexPath.section];
    ZHDPListRowItem *rowItem = secItem.rowItems[indexPath.row];
    
    ZHDPListCell *cell = [ZHDPListCell cellWithTableView:tableView];
    __weak __typeof__(self) weakSelf = self;
    cell.tapGesBlock = ^(void) {
        [weakSelf.detail showWithSecItem:secItem];
    };
    cell.longPressGesBlock = ^(void) {
        [ZHDPMg() copySecItemToPasteboard:secItem];
    };
    [cell configItem:rowItem];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
// 将要开始拖拽
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.scrollStatus = ZHDPScrollStatus_Dragging;
    [self updateScrollAuto];
}
// 将要结束拖拽
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    self.scrollStatus = ZHDPScrollStatus_Dragging;
    [self updateScrollAuto];
}
// 结束拖拽
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    self.scrollStatus = decelerate ? ZHDPScrollStatus_DraggingDecelerate : ZHDPScrollStatus_Idle;
    [self updateScrollAuto];
    if (!decelerate) {
        [self updateSecItemWhenScrollEnd];
    }
//    NSLog(@"%s",__func__);
}
// 将要开始减速（手指拖动才会调用）
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    self.scrollStatus = ZHDPScrollStatus_DraggingDecelerate;
//    NSLog(@"%s",__func__);
}
// 完成减速（手指拖动才会调用）
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    self.scrollStatus = ZHDPScrollStatus_Idle;
    [self updateScrollAuto];
    [self updateSecItemWhenScrollEnd];
//    NSLog(@"%s",__func__);
}
// called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
//    [self updateScrollAuto];
//    NSLog(@"%s",__func__);
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
}

#pragma mark - getter

- (NSMutableArray<ZHDPListSecItem *> *)items{
    if (!_items) {
        _items = [NSMutableArray array];
    }
    return _items;
}
- (NSMutableArray<ZHDPListSecItem *> *)items_temp{
    if (!_items_temp) {
        _items_temp = [NSMutableArray array];
    }
    return _items_temp;
}
- (NSMutableArray<ZHDPListSecItem *> *)removeItems_temp{
    if (!_removeItems_temp) {
        _removeItems_temp = [NSMutableArray array];
    }
    return _removeItems_temp;
}
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        
        _tableView.directionalLockEnabled = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        if (@available(iOS 11.0, *)){
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }else{
//            self.automaticallyAdjustsScrollViewInsets = YES;
        }
        
        // 防止 < xcode13 的版本编译失败
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_15_0
        /** 适配iOS15 xcode13
         原来是SectionHeader在滚动时，下面的SectionHeader是推着上面的SectionHeader出屏幕的。
         升级后SectionHeader在滚动时，下面的SectionHeader是滚到上面的SectionHeader下面，直到完全占据其位置才显示。
         */
        if (@available(iOS 15.0, *)){
            _tableView.sectionHeaderTopPadding = 0;
        }
        
        // 全局设置
//        if (@available(iOS 15.0, *)) {
//            [UITableView appearance].sectionHeaderTopPadding = 0;
//        }
#endif
        
//        _tableView.separatorColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.25];
//        _tableView.separatorInset = UIEdgeInsetsZero;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}
- (ZHDPListSearch *)search{
    if (!_search) {
        _search = [[ZHDPListSearch alloc] initWithFrame:CGRectZero];
        _search.list = self;
        __weak __typeof__(self) weakSelf = self;
        _search.fieldChangeBlock = ^(NSString *str) {
            [weakSelf reloadListWhenSearch];
        };
    }
    return _search;
}
- (ZHDPListOprate *)oprate{
    if (!_oprate) {
        _oprate = [[ZHDPListOprate alloc] initWithFrame:CGRectZero];
        _oprate.list = self;
    }
    return _oprate;
}
- (ZHDPListApps *)apps{
    if (!_apps) {
        _apps = [[ZHDPListApps alloc] initWithFrame:CGRectZero];
        __weak __typeof__(self) weakSelf = self;
        _apps.selectBlock = ^(ZHDPFilterItem * _Nonnull item) {
            [weakSelf selectListApps:item];
        };
        _apps.list = self;
    }
    return _apps;
}
- (ZHDPListDetail *)detail{
    if (!_detail) {
        _detail = [[ZHDPListDetail alloc] initWithFrame:CGRectZero];
        _detail.list = self;
    }
    return _detail;
}
- (ZHDPListOption *)option{
    if (!_option) {
        _option = [[ZHDPListOption alloc] initWithFrame:CGRectZero];
        _option.list = self;
    }
    return _option;
}
- (ZHDPListSpace *)space{
    if (!_space) {
        _space = [[ZHDPListSpace alloc] initWithFrame:CGRectZero];
        _space.list = self;
    }
    return _space;
}
- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _tipLabel.font = [ZHDPMg() defaultFont];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.text = [self footerTipTitle];
        _tipLabel.numberOfLines = 0;
        _tipLabel.textColor = [UIColor blackColor];
        _tipLabel.backgroundColor = [UIColor clearColor];
        _tipLabel.adjustsFontSizeToFitWidth = NO;
    }
    return _tipLabel;
}

@end
