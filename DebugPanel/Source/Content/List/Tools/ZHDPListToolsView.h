//
//  ZHDPListToolsView.h
//  Pods-Demo
//
//  Created by EM on 2022/1/21.
//

#import "ZHDPComponent.h"
#import "ZHDPDataTask.h"// 数据管理
@class ZHDPList;

@interface ZHDPListToolCollectionViewCell : UICollectionViewCell
- (void)configItem:(ZHDPListToolItem *)item;

- (void)configTitleHideEnable:(BOOL)enable;
- (void)configNormalStyle;
- (void)configHighlightStyle;
@end

@interface ZHDPListToolsView : ZHDPComponent <UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic,weak) ZHDPList *list;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic,retain) NSArray <ZHDPListToolItem *> *items;
- (void)reloadWithItems:(NSArray <ZHDPListToolItem *> *)items;

#pragma mark - config

- (void)configUI;

#pragma mark - reload

- (void)reloadCollectionViewFrequently;
- (void)reloadCollectionView;

@end

