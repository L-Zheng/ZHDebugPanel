//
//  ZHDPListApps.h
//  ZHJSNative
//
//  Created by EM on 2021/5/28.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListPop.h"
#import "ZHDPDataTask.h"// 数据管理

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPListApps : ZHDPListPop
@property (nonatomic,strong) ZHDPFilterItem *selectItem;
@property (nonatomic,copy) void (^selectBlock) (ZHDPFilterItem *item);

#pragma mark - select

- (void)selectItemByAppId:(NSString *)appId;

@end

NS_ASSUME_NONNULL_END
