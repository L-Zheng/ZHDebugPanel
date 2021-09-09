//
//  ZHDPFilterPage.h
//  Pods-Demo
//
//  Created by EM on 2021/9/9.
//

#import "ZHDPFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPFilterPage : ZHDPFilter

@property (nonatomic,strong) ZHDPFilterItem *selectItem;
@property (nonatomic,copy) void (^selectBlock) (ZHDPFilterItem *item);

#pragma mark - data

- (void)reloadItem:(ZHDPFilterListItem *)item;

@end

NS_ASSUME_NONNULL_END
