//
//  ZHDPContent.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPContent.h"
#import "ZHDPDataTask.h"// 数据管理
#import "ZHDPList.h"// 列表
#import "ZHDPManager.h"

@interface ZHDPContent ()
@property (nonatomic, retain) NSArray *allList;
@end

@implementation ZHDPContent

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
    
    self.selectList.frame = self.bounds;
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor whiteColor];
}

#pragma mark - lists

- (NSArray <ZHDPList *> *)fetchAllLists{
    if (self.allList) return self.allList;
    NSMutableArray *res = [NSMutableArray array];
    NSArray *configs = [ZHDPMg() fetchListConfig];
    for (NSArray *config in configs) {
        if ([config[0] boolValue]) {
            [res addObject:[self createList:config[1] title:config[2]]];
        }
    }
    self.allList = res.copy;
    return self.allList;
}
- (ZHDPList *)createList:(Class)class title:(NSString *)title{
    ZHDPList *list = [[class alloc] initWithFrame:CGRectZero];
    list.item = [ZHDPListItem itemWithTitle:title];
    __weak __typeof__(list) __list = list;
    __weak __typeof__(self) __self = self;
    list.reloadListBlock = ^(NSArray<ZHDPListSecItem *> * _Nonnull items) {
        if (__self.reloadListBlock) {
            __self.reloadListBlock(__list, items);
        }
    };
    return list;
}
- (void)selectList:(ZHDPList *)list belowSubview:(UIView *)belowSubview{
    if (!list || [self.selectList isEqual:list]) return;
    
    ZHDPList *originList = self.selectList;
    if ([originList isFirstResponder]) {
        if ([list isShowSearch]) {
            [originList resignFirstResponder];
//            [list becomeFirstResponder];
        }else{
            [originList resignFirstResponder];
        }
    }
    self.selectList = list;
    
    [originList removeFromSuperview];
    if (belowSubview) {
        [self insertSubview:self.selectList belowSubview:belowSubview];
    }else{
        [self addSubview:self.selectList];
    }
    self.selectList.frame = self.bounds;
}
@end
