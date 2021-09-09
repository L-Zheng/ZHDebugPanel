//
//  ZHDPFilterType.h
//  Pods-Demo
//
//  Created by EM on 2021/9/9.
//

#import "ZHDPFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPFilterType : ZHDPFilter

@property (nonatomic,strong) ZHDPOutputItem *selectItem;
@property (nonatomic,copy) void (^selectBlock) (ZHDPOutputItem *item);

- (void)reloadItems;

@end

NS_ASSUME_NONNULL_END
