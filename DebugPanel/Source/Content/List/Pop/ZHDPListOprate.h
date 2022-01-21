//
//  ZHDPListOprate.h
//  ZHJSNative
//
//  Created by EM on 2021/5/28.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListPop.h"
#import "ZHDPDataTask.h"// 数据管理

@interface ZHDPListOprate : ZHDPListPop
- (void)reloadWithItems:(NSArray <ZHDPListToolItem *> *)items;
@end
