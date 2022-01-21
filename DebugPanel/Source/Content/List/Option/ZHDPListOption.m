//
//  ZHDPListOption.m
//  ZHJSNative
//
//  Created by EM on 2021/6/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListOption.h"
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPList.h"// 列表

@interface ZHDPListOption ()
@end

@implementation ZHDPListOption

#pragma mark - override

- (void)layoutSubviews{
    [super layoutSubviews];
    
    NSUInteger count = MIN(self.items.count, 9);
    CGFloat W = count > 0 ? self.bounds.size.width * 1.0 / (count * 1.0) : self.bounds.size.width;
    CGFloat H = self.bounds.size.height;
    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(W, H);
    }
    self.collectionView.frame = self.bounds;
    [self reloadCollectionViewFrequently];
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    [super configUI];
    self.backgroundColor = [ZHDPMg() bgColor];
}

#pragma mark - UICollectionViewDelegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZHDPListToolCollectionViewCell *cell = [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    ZHDPListToolItem *item = self.items[indexPath.item];
    [cell configTitleHideEnable:!item.isSelected];
    return cell;
}
@end
