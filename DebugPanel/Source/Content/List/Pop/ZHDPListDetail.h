//
//  ZHDPListDetail.h
//  ZHJSNative
//
//  Created by EM on 2021/5/29.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListPop.h"
#import "ZHDPDataTask.h"// 数据管理

@interface ZHDPListDetailCollectionViewCell : UICollectionViewCell
- (void)configItem:(ZHDPListDetailItem *)item;
@end

@interface ZHDPListDetail : ZHDPListPop
- (void)showWithSecItem:(ZHDPListSecItem *)secItem;
@property (nonatomic,weak) ZHDPListSecItem *secItem;

#pragma mark - hyalinize
// 透明化
- (void)hyalinize;
- (void)hyalinizeCancel;

@end
