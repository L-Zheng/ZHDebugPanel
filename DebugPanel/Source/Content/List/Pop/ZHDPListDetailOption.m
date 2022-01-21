//
//  ZHDPListDetailOption.m
//  ZHDebugPanel
//
//  Created by Zheng on 2021/10/30.
//

#import "ZHDPListDetailOption.h"
#import "ZHDPManager.h"// 调试面板管理

@interface ZHDPListDetailOption ()
@end

@implementation ZHDPListDetailOption

#pragma mark - override

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat H = self.bounds.size.height;
    CGFloat W = H + 0;
    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(W, H);
    }
    self.collectionView.frame = self.bounds;
    [self reloadCollectionViewFrequently];
}

#pragma mark - config

- (void)configUI{
    [super configUI];
}

#pragma mark - UICollectionViewDelegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZHDPListToolCollectionViewCell *cell = [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    [cell configTitleHideEnable:YES];
    return cell;
}

@end
