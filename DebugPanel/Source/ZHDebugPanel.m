//
//  ZHDebugPanel.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDebugPanel.h"
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPOption.h"// 操作栏
#import "ZHDPContent.h"// 内容列表容器
#import "ZHDPList.h"// 列表
#import "ZHDPDataTask.h"// 数据管理

@interface ZHDebugPanel ()
@property (nonatomic,strong) ZHDPOptionExpan *optionExpan;
@end

@implementation ZHDebugPanel

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
    
    UIEdgeInsets safeAreaInsets = [ZHDPMg() fetchKeyWindowSafeAreaInsets];
    CGFloat marginBottom = safeAreaInsets.bottom;
    self.option.frame = CGRectMake(0, 0, self.bounds.size.width, 40);

    CGFloat contentY = CGRectGetMaxY(self.option.frame);
    CGFloat contentH = self.bounds.size.height - contentY - marginBottom;
    self.content.frame = CGRectMake(0, contentY, self.bounds.size.width, contentH);
    
    self.optionExpan.frame = self.content.bounds;
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
    BOOL show = self.superview;
    self.status = show ? ZHDebugPanelStatus_Show : ZHDebugPanelStatus_Hide;
    
    if (!show) return;
    [self reloadAndSelectOptionOnlyOnce:0];
    
    if (self.content.selectList) {
        [self.content.selectList reloadListWhenShow];
    }
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [ZHDPMg() bgColor];

    [self addSubview:self.option];
    [self addSubview:self.content];
}

#pragma mark - option

- (void)selectOption:(NSInteger)idx{
    [self.option selectIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
}
- (void)reloadAndSelectOptionOnlyOnce:(NSInteger)idx{
    if (self.option.selectItem) return;
    [self reloadAndSelectOption:idx];
}
- (void)reloadAndSelectOption:(NSInteger)idx{
    NSMutableArray <ZHDPOptionItem *> *items = [NSMutableArray array];
    
    NSArray <ZHDPList *> *lists = [self.content fetchAllLists].copy;
    for (ZHDPList *list in lists) {
        ZHDPOptionItem *item = [[ZHDPOptionItem alloc] init];
        item.title = list.item.title;
        item.selected = NO;
        item.list = list;
        item.font = [UIFont systemFontOfSize:17];
        
        [items addObject:item];
    }
    
    [self.option reloadWithItems:items.copy];
    [self selectOption:idx];
}
- (void)reloadOptionItemByList:(ZHDPList *)list items:(NSArray *)items{
    NSArray <ZHDPList *> *lists = [self.content fetchAllLists].copy;
    NSUInteger idx = [lists indexOfObject:list];
    if (idx == NSNotFound || idx >= lists.count) {
        return;
    }
    NSArray *optionItems = self.option.items.copy;
    if (idx >= optionItems.count) {
        return;
    }
    ZHDPOptionItem *item = optionItems[idx];
    item.itemsCount = items.count;
    [self.option reloadCollectionViewFrequently];
}

#pragma mark - optionExpan

- (void)showOptionExpan:(NSArray *)items{
    [self.optionExpan showOptionExpan:self.content items:items];
}
- (void)hideOptionExpan{
    [self.optionExpan hideOptionExpan];
}

#pragma mark - getter

- (ZHDPOption *)option{
    if (!_option) {
        _option = [[ZHDPOption alloc] initWithFrame:CGRectZero];
        __weak __typeof__(self) weakSelf = self;
        _option.selectBlock = ^(NSIndexPath *indexPath, ZHDPOptionItem *item) {
            [weakSelf.content selectList:item.list belowSubview:weakSelf.optionExpan.superview ? weakSelf.optionExpan : nil];
        };
        _option.debugPanel = self;
    }
    return _option;
}
- (ZHDPOptionExpan *)optionExpan{
    if (!_optionExpan) {
        _optionExpan = [[ZHDPOptionExpan alloc] initWithFrame:CGRectZero];
        __weak __typeof__(self) weakSelf = self;
        _optionExpan.selectBlock = ^(NSIndexPath *indexPath, ZHDPOptionItem *item) {
            [weakSelf.option selectIndexPath:indexPath];
        };
        _optionExpan.debugPanel = self;
    }
    return _optionExpan;
}
- (ZHDPContent *)content{
    if (!_content) {
        _content = [[ZHDPContent alloc] initWithFrame:CGRectZero];
        _content.debugPanel = self;
        __weak __typeof__(self) weakSelf = self;
        _content.reloadListBlock = ^(ZHDPList * _Nonnull list, NSArray<ZHDPListSecItem *> * _Nonnull items) {
            [weakSelf reloadOptionItemByList:list items:items];
        };
    }
    return _content;
}
@end
