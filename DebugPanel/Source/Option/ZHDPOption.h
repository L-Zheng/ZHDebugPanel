//
//  ZHDPOption.h
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
@class ZHDPList;// 列表

@interface ZHDPOptionItem : NSObject
@property (nonatomic,copy,readonly) NSString *showTitle;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,assign) NSInteger itemsCount;
@property (nonatomic,assign,getter=isSelected) BOOL selected;
@property (nonatomic,weak) ZHDPList *list;
@property (nonatomic,strong) UIFont *font;
@end

@interface ZHDPOptionCollectionViewCell : UICollectionViewCell
- (void)configItem:(ZHDPOptionItem *)item;
@end

@interface ZHDPOption : ZHDPComponent
@property (nonatomic,copy) void (^selectBlock) (NSIndexPath *indexPath, ZHDPOptionItem *item);

@property (nonatomic,strong) ZHDPOptionItem *selectItem;
@property (nonatomic, retain) NSArray <ZHDPOptionItem *> *items;
- (void)reloadWithItems:(NSArray <ZHDPOptionItem *> *)items;
- (void)reloadCollectionViewFrequently;
- (void)selectIndexPath:(NSIndexPath *)indexPath;
@end
