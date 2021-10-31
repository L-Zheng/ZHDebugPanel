//
//  ZHDPListDetail.m
//  ZHJSNative
//
//  Created by EM on 2021/5/29.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListDetail.h"
#import "ZHDPList.h"// 列表
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPListDetailOption.h"

@interface ZHDPListDetailCollectionViewCell()
@property (nonatomic, strong) UILabel *label;
@end
@implementation ZHDPListDetailCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
    //    cell.contentView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255.0)/255.0 green:arc4random_uniform(255.0)/255.0 blue:arc4random_uniform(255.0)/255.0 alpha:0.5];
        
        [self.contentView addSubview:self.label];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    self.label.frame = self.contentView.bounds;
}
- (void)configItem:(ZHDPListDetailItem *)item{
    self.label.text = [NSString stringWithFormat:@"%@", item.title];
    self.label.textColor = item.isSelected ? [ZHDPMg() selectColor] : [ZHDPMg() defaultColor];
}
- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.textAlignment = NSTextAlignmentLeft;
        _label.adjustsFontSizeToFitWidth = YES;
        _label.font = [ZHDPMg() defaultFont];
    }
    return _label;
}
@end

@interface ZHDPListDetail ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, retain) NSArray <ZHDPListDetailItem *> *items;
@property (nonatomic,strong) UIView *contentView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic,strong) UIView *line;
@property (nonatomic,strong) UIView *bottomLine;
@property (nonatomic,strong) UITextView *textView;
@property (nonatomic,strong) ZHDPListDetailOption *option;

@property (nonatomic,assign) NSInteger lastSelectIdx;
@end

@implementation ZHDPListDetail

#pragma mark - override

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configUI];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];

    self.contentView.frame = self.shadowView.frame;
    
    CGFloat X = [ZHDPMg() marginW] * 2;
    CGFloat W = self.contentView.frame.size.width - 2 * X;
    CGFloat H = 35;
    CGFloat Y = 0;
//    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
//    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
//        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(50, H);
//    }
    self.collectionView.frame = CGRectMake(X, Y, W, H);
    
    X = 0;
    W = self.contentView.frame.size.width;
    H = [ZHDPMg() defaultLineW];
    Y = CGRectGetMaxY(self.collectionView.frame);
    self.line.frame = CGRectMake(X, Y, W, H);
    
    X = self.collectionView.frame.origin.x;
    W = self.collectionView.frame.size.width;
    H = 35;
    Y = self.contentView.frame.size.height - H;
    self.option.frame = CGRectMake(X, Y, W, H);
    
    X = 0;
    W = self.contentView.frame.size.width;
    H = [ZHDPMg() defaultLineW];
    Y = self.option.frame.origin.y - H;
    self.bottomLine.frame = CGRectMake(X, Y, W, H);
    
    X = [ZHDPMg() marginW];
    W = self.contentView.frame.size.width - X - [ZHDPMg() marginW];
    Y = CGRectGetMaxY(self.line.frame);
    H = self.bottomLine.frame.origin.y - Y;
    self.textView.frame = CGRectMake(X, Y, W, H);
    
    [self reloadListFrequently];
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
}
- (CGFloat)defaultPopW{
    return [self minPopW];
}
- (CGFloat)minPopW{
    return 250;
}
- (CGFloat)maxPopW{
    return self.list.bounds.size.width - 20;
}
- (void)showWithSecItem:(ZHDPListSecItem *)secItem{
    NSArray <ZHDPListDetailItem *> *items = secItem.detailItems;
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return;
    }
    
    [ZHDPMg().window enableDebugPanel:NO];
    
    if ([self isShow]) {
        if (![self.secItem isEqual:secItem]) {
            [self reloadWithSecItem:secItem];
        }
        [ZHDPMg().window enableDebugPanel:YES];
        return;
    }
    
    [self updateFrameX:YES];
    [self.list addSubview:self];
    [self reloadWithSecItem:secItem];
    
    [super show];
    [ZHDPMg() doAnimation:^{
        [self updateFrameX:NO];
    } completion:^(BOOL finished) {
        [ZHDPMg().window enableDebugPanel:YES];
    }];
}
- (void)hide{
    [ZHDPMg().window enableDebugPanel:NO];
    if (![self isShow]) {
        [ZHDPMg().window enableDebugPanel:YES];
        return;
    }
    
    [super hide];
    [ZHDPMg() doAnimation:^{
        [self updateFrameX:YES];
    } completion:^(BOOL finished) {
        self.secItem = nil;
        [self removeFromSuperview];
        [ZHDPMg().window enableDebugPanel:YES];
    }];
}
- (BOOL)allowMaskWhenShow{
    return NO;
}
- (void)reloadList{
    [self.collectionView reloadData];
}

#pragma mark - config

- (void)configUI{
    [super configUI];
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.collectionView];
    [self.contentView addSubview:self.line];
    [self.contentView addSubview:self.textView];
    [self.contentView addSubview:self.bottomLine];
    [self.contentView addSubview:self.option];
    [self reloadOptionList];
}

#pragma mark - relaod

- (void)reloadWithSecItem:(ZHDPListSecItem *)secItem{
    self.secItem = secItem;
    NSArray <ZHDPListDetailItem *> *items = secItem.detailItems;
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return;
    }
    for (id item in items) {
        if (![item isKindOfClass:ZHDPListDetailItem.class]) {
            return;
        }
    }
    self.items = items.copy;
    
    [self selectItem:(self.lastSelectIdx >= items.count ?  items.firstObject : items[self.lastSelectIdx])];
    [self scrollTextViewToTopFrequently];
}
- (void)reloadOptionList{
    NSMutableArray *res = [NSMutableArray array];
    __weak __typeof__(self) weakSelf = self;
    NSArray *icons = @[@"\ueb6a", @"\ue617"];
    NSArray *descs = @[@"关闭", @"复制"];
    NSArray *blocks = @[
        ^{
            [weakSelf hide];
        },
         ^{
             [ZHDPMg() copySecItemToPasteboard:weakSelf.secItem];
         }
    ];
    for (NSUInteger i = 0; i < icons.count; i++) {
        ZHDPListOprateItem *item = [[ZHDPListOprateItem alloc] init];
        item.icon = icons[i];
        item.desc = descs[i];
        item.textColor = [ZHDPMg() defaultColor];
        item.block = [blocks[i] copy];
        [res addObject:item];
    }
    [self.option reloadWithItems:res.copy];
}

#pragma mark - select

- (void)selectItem:(ZHDPListDetailItem *)item{
    if (![self.items containsObject:item]) return;
    NSUInteger idx = [self.items indexOfObject:item];
    [self selectIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
}
- (void)selectIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= self.items.count) return;
    
    for (NSUInteger i = 0; i < self.items.count; i++) {
        self.items[i].selected = (indexPath.item == i ? YES : NO);
    }
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    [self reloadListInstant];
    NSAttributedString *text = self.items[indexPath.item].content;
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:@"载入中..." attributes:@{NSFontAttributeName: [ZHDPMg() defaultFont], NSForegroundColorAttributeName: [ZHDPMg() selectColor]}];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.textView.attributedText = text;
    });

    self.lastSelectIdx = indexPath.item;
}
- (void)scrollTextViewToTopFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollTextViewToTopInstant) object:nil];
    [self performSelector:@selector(scrollTextViewToTopInstant) withObject:nil afterDelay:0.25];
}
- (void)scrollTextViewToTopInstant{
    [self.textView setContentOffset:CGPointMake(0, 0) animated:YES];
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZHDPListDetailCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.collectionCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    //    cell.contentView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255.0)/255.0 green:arc4random_uniform(255.0)/255.0 blue:arc4random_uniform(255.0)/255.0 alpha:1.0];
    cell.contentView.backgroundColor = [UIColor clearColor];
    ZHDPListDetailItem *item = self.items[indexPath.item];
    [cell configItem:item];
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat H = collectionView.bounds.size.height;
    ZHDPListDetailItem *item = self.items[indexPath.item];
    if (item.fitWidth <= 0) {
        item.fitWidth = [item.title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, H) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [ZHDPMg() defaultFont]} context:nil].size.width;
    }
    return CGSizeMake(item.fitWidth + 2 * 8, H);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self selectIndexPath:indexPath];
}

#pragma mark - getter

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                
//        [Assert] negative or zero item sizes are not supported in the flow layout
        layout.itemSize = CGSizeMake(1, 1);
        
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.directionalLockEnabled = YES;
        
        [_collectionView registerClass:[ZHDPListDetailCollectionViewCell class] forCellWithReuseIdentifier:self.collectionCellIdentifier];
    }
    return _collectionView;
}
- (NSString *)collectionCellIdentifier{
    return [NSString stringWithFormat:@"%@_CollectionViewCell", NSStringFromClass(self.class)];
}
- (UIView *)contentView{
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.clipsToBounds = YES;
    }
    return _contentView;
}
- (UIView *)line{
    if (!_line) {
        _line = [[UIView alloc] initWithFrame:CGRectZero];
        _line.backgroundColor = [ZHDPMg() defaultLineColor];
    }
    return _line;
}
- (UIView *)bottomLine{
    if (!_bottomLine) {
        _bottomLine = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomLine.backgroundColor = [ZHDPMg() defaultLineColor];
    }
    return _bottomLine;
}
- (UITextView *)textView{
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectZero];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [ZHDPMg() defaultFont];
        _textView.editable = NO;
        _textView.alwaysBounceVertical = YES;
    }
    return _textView;
}
- (ZHDPListDetailOption *)option{
    if (!_option) {
        _option = [[ZHDPListDetailOption alloc] initWithFrame:CGRectZero];
    }
    return _option;
}
@end
