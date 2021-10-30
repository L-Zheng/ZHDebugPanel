//
//  ZHDPListOption.h
//  ZHJSNative
//
//  Created by EM on 2021/6/17.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
#import "ZHDPListOprate.h"// pop操作栏
@class ZHDPList;

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPListOption : ZHDPComponent
@property (nonatomic,weak) ZHDPList *list;

@property (nonatomic, strong) UICollectionView *collectionView;
- (void)reloadWithItems:(NSArray <ZHDPListOprateItem *> *)items;

#pragma mark - config

- (void)configUI;

#pragma mark - reload

- (void)reloadCollectionViewFrequently;
@end

NS_ASSUME_NONNULL_END
