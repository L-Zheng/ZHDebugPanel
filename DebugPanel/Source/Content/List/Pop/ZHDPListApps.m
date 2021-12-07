//
//  ZHDPListApps.m
//  ZHJSNative
//
//  Created by EM on 2021/5/28.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListApps.h"
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPList.h"// 列表
#import "ZHDPFilterApp.h"
#import "ZHDPFilterPage.h"
#import "ZHDPFilterType.h"

@interface ZHDPListApps ()
@property (nonatomic,strong) UILabel *topTipLabel;
@property (nonatomic,strong) UIButton *selectAllBtn;
@property (nonatomic,strong) UIButton *cancelBtn;
@property (nonatomic,strong) UIButton *sureBtn;
@property (nonatomic,strong) ZHDPFilterApp *filterApp;
@property (nonatomic,strong) ZHDPFilterPage *filterPage;
@property (nonatomic,strong) ZHDPFilterType *filterType;
@end

@implementation ZHDPListApps

#pragma mark - override

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configUI];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat X = self.shadowView.frame.origin.x;
    CGFloat Y = 0;
    CGFloat W = self.shadowView.frame.size.width;
    CGFloat H = 44;
    self.topTipLabel.frame = CGRectMake(X, Y, W, H);
    
    
    CGFloat splitScale = 1.0 / 3.0;
    
    X = self.shadowView.frame.origin.x;
    H = 44;
    Y = self.shadowView.frame.size.height - H;
    W = self.shadowView.frame.size.width * splitScale;
    self.cancelBtn.frame = CGRectMake(X, Y, W, H);
    
    self.sureBtn.frame = CGRectMake(CGRectGetMaxX(self.cancelBtn.frame), Y, W, H);
    
    self.selectAllBtn.frame = CGRectMake(CGRectGetMaxX(self.sureBtn.frame), Y, W, H);
    
    X = self.shadowView.frame.origin.x;
    Y = CGRectGetMaxY(self.topTipLabel.frame);
    W = self.shadowView.frame.size.width * splitScale;
    H = self.selectAllBtn.frame.origin.y - Y;
    self.filterApp.frame = CGRectMake(X, Y, W, H);
    
    self.filterPage.frame = CGRectMake(CGRectGetMaxX(self.filterApp.frame), Y, W, H);
    
    self.filterType.frame = CGRectMake(CGRectGetMaxX(self.filterPage.frame), Y, W, H);
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
//    BOOL show = self.superview;
//    if (!show) return;
}

- (CGFloat)defaultPopW{
    return 250;
}
- (CGFloat)minPopW{
    return 200;
}
- (CGFloat)maxPopW{
    return self.list.bounds.size.width - 20;
}
- (void)show{
    [ZHDPMg().window enableDebugPanel:NO];
    if ([self isShow]) {
        [ZHDPMg().window enableDebugPanel:YES];
        return;
    }
    
    [self updateFrameX:YES];
    [self.list addSubview:self];
    [self reloadSecItems];
    
    [super show];
    [ZHDPMg() doAnimation:^{
        [self updateFrameX:NO];
    } completion:^(BOOL finished) {
        [ZHDPMg().window enableDebugPanel:YES];
    }];
}
- (void)hide{
    [ZHDPMg().window enableDebugPanel:NO];
    if (![self isShow]) {
        [ZHDPMg().window enableDebugPanel:YES];
        return;
    }
    
    [super hide];
    [ZHDPMg() doAnimation:^{
        [self updateFrameX:YES];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [ZHDPMg().window enableDebugPanel:YES];
    }];
}
- (BOOL)allowMaskWhenShow{
    return YES;
}
- (void)reloadList{
}

#pragma mark - config

- (void)configUI{
    [super configUI];
    [self addSubview:self.topTipLabel];
    [self addSubview:self.filterApp];
    [self addSubview:self.filterPage];
    [self addSubview:self.filterType];
    [self addSubview:self.selectAllBtn];
    [self addSubview:self.cancelBtn];
    [self addSubview:self.sureBtn];
}

#pragma mark - data

- (void)reloadSecItems{
    NSArray <ZHDPListSecItem *> *secItems = [self.list fetchAllItems]?:@[];
    
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    for (ZHDPListSecItem *secItem in secItems) {
        @autoreleasepool {
            ZHDPFilterItem *filterItem = secItem.filterItem;
            ZHDPAppItem *appItem = filterItem.appItem;
            NSString *appId = appItem.appId;
            if (!appId || ![appId isKindOfClass:NSString.class] || appId.length == 0) {
                continue;
            }
            ZHDPFilterListItem *listItem = [map objectForKey:appId];
            if (!listItem) {
                listItem = [[ZHDPFilterListItem alloc] init];
                [map setObject:listItem forKey:appId];
            }
            listItem.appItem = appItem;
            
            if (!filterItem.page || ![filterItem.page isKindOfClass:NSString.class] || filterItem.page.length == 0) {
                continue;
            }
            
            NSMutableArray *subItems = [NSMutableArray arrayWithArray:listItem.pageFilterItems?:@[]];
            
            BOOL contain = NO;
            for (ZHDPFilterItem *filterItemTemp in subItems) {
                if ((!filterItemTemp.page && !filterItem.page) ||
                    [filterItemTemp.page isEqualToString:filterItem.page]) {
                    contain = YES;
                    break;
                }
            }
            if (contain) continue;
            
            [subItems addObject:filterItem];
            listItem.pageFilterItems = subItems.copy;
        }
    }
    NSMutableArray *newListItems = [NSMutableArray array];
    NSArray *listItems = map.allValues;
    ZHDPFilterListItem *fundCliItem = nil;
    for (ZHDPFilterListItem *listItem in listItems) {
        if (listItem.appItem.isFundCli) {
            fundCliItem = listItem;
        }else{
            [newListItems addObject:listItem];
        }
    }
    if (fundCliItem) {
        [newListItems insertObject:fundCliItem atIndex:0];
    }
    [self.filterApp reloadItems:newListItems];
    [self.filterType reloadItems];
}

#pragma mark - select

- (void)selectItem:(ZHDPFilterItem *)item{
    self.selectItem = item;
    if (self.selectBlock) self.selectBlock(self.selectItem);
}
- (void)selectItemByAppId:(NSString *)appId{
    if (!appId || ![appId isKindOfClass:NSString.class] || appId.length == 0) {
        return;
    }
    [self reloadSecItems];
    if ([self.filterApp selectItemByAppId:appId]) {
        [self sureBtnClick:nil];
    }
}

#pragma mark - click

- (void)selectAllBtnClick:(UIButton *)btn{
    [self.filterApp selectAllBtnClick];
    [self.filterPage selectAllBtnClick];
    [self.filterType selectAllBtnClick];
    [self selectItem:nil];
}
- (void)cancelBtnClick:(UIButton *)btn{
    [self hide];
}
- (void)sureBtnClick:(UIButton *)btn{
    ZHDPFilterItem *item = [[ZHDPFilterItem alloc] init];
    item.appItem = self.filterApp.selectItem.appItem;
    if (!item.appItem) {
        item.page = nil;
    }else{
        if (!self.filterPage.selectItem) {
            item.page = nil;
        }else{
            if ([item.appItem.appId isEqualToString:self.filterPage.selectItem.appItem.appId]) {
                item.page = self.filterPage.selectItem.page;
            }else{
                item.page = nil;
            }
        }
    }
    item.outputItem = self.filterType.selectItem;
    [self selectItem:item];
}

#pragma mark - getter

- (ZHDPFilterApp *)filterApp{
    if (!_filterApp) {
        _filterApp = [[ZHDPFilterApp alloc] initWithFrame:CGRectZero];
        __weak __typeof__(self) __self = self;
        _filterApp.selectBlock = ^(ZHDPFilterListItem * _Nonnull item) {
            [__self.filterPage reloadItem:item];
        };
    }
    return _filterApp;
}
- (ZHDPFilterPage *)filterPage{
    if (!_filterPage) {
        _filterPage = [[ZHDPFilterPage alloc] initWithFrame:CGRectZero];
        _filterPage.selectBlock = ^(ZHDPFilterItem * _Nonnull item) {
            
        };
    }
    return _filterPage;
}
- (ZHDPFilterType *)filterType{
    if (!_filterType) {
        _filterType = [[ZHDPFilterType alloc] initWithFrame:CGRectZero];
        _filterType.selectBlock = ^(ZHDPOutputItem * _Nonnull item) {
            
        };
    }
    return _filterType;
}
- (UILabel *)topTipLabel {
    if (!_topTipLabel) {
        _topTipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _topTipLabel.font = [ZHDPMg() defaultBoldFont];
        _topTipLabel.textAlignment = NSTextAlignmentCenter;
        _topTipLabel.text = @"筛选";
        _topTipLabel.textColor = [UIColor blackColor];
        _topTipLabel.backgroundColor = [UIColor clearColor];
        _topTipLabel.adjustsFontSizeToFitWidth = NO;
    }
    return _topTipLabel;
}
- (UIButton *)selectAllBtn{
    if (!_selectAllBtn) {
        _selectAllBtn = [self createBtn:@"选择全部" action:@selector(selectAllBtnClick:)];
    }
    return _selectAllBtn;
}
- (UIButton *)cancelBtn{
    if (!_cancelBtn) {
        _cancelBtn = [self createBtn:@"取消" action:@selector(cancelBtnClick:)];
    }
    return _cancelBtn;
}
- (UIButton *)sureBtn{
    if (!_sureBtn) {
        _sureBtn = [self createBtn:@"确定" action:@selector(sureBtnClick:)];
    }
    return _sureBtn;
}
- (UIButton *)createBtn:(NSString *)title action:(SEL)action{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectZero];
    btn.backgroundColor = [UIColor clearColor];
    btn.titleLabel.font = [ZHDPMg() defaultBoldFont];
    btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}
@end
