//
//  ZHDPListOprateOption.m
//  Pods-Demo
//
//  Created by EM on 2022/1/21.
//

#import "ZHDPListOprateOption.h"

@implementation ZHDPListOprateOption

#pragma mark - override

- (void)layoutSubviews{
    [super layoutSubviews];
}

#pragma mark - config

- (void)configUI{
    [super configUI];
    
    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
        ((UICollectionViewFlowLayout *)layout).scrollDirection = UICollectionViewScrollDirectionVertical;
    }
    
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = YES;
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.directionalLockEnabled = YES;
}
@end
