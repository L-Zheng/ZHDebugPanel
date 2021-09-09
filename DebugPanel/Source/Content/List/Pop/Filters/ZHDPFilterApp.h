//
//  ZHDPFilterApp.h
//  Pods-Demo
//
//  Created by EM on 2021/9/9.
//

#import "ZHDPFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPFilterApp : ZHDPFilter
@property (nonatomic,strong) ZHDPFilterListItem *selectItem;
@property (nonatomic,copy) void (^selectBlock) (ZHDPFilterListItem *item);

#pragma mark - data

- (void)reloadItems:(NSArray <ZHDPFilterListItem *> *)items;

@end

NS_ASSUME_NONNULL_END
