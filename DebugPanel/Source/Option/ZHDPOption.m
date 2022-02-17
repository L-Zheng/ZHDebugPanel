//
//  ZHDPOption.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPOption.h"
#import "ZHDebugPanel.h"// 调试面板
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPList.h"//列表

@implementation ZHDPOptionItem
- (NSString *)showTitle{
    NSUInteger count = self.itemsCount;
    if (count == 0) {
        return self.title;
    }
    return [NSString stringWithFormat:@"%@(%ld)", self.title, count];
}
@end

@interface ZHDPOptionCollectionViewCell()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic,strong) UIView *line;
@end
@implementation ZHDPOptionCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
    //    cell.contentView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255.0)/255.0 green:arc4random_uniform(255.0)/255.0 blue:arc4random_uniform(255.0)/255.0 alpha:0.5];
        
        [self.contentView addSubview:self.label];
        [self.contentView addSubview:self.line];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.label.frame = self.contentView.bounds;
    
    CGFloat W = 1.0 / UIScreen.mainScreen.scale;
    CGFloat H = self.bounds.size.height;
    CGFloat X = self.bounds.size.width - W;
    CGFloat Y = 0;
    self.line.frame = CGRectMake(X, Y, W, H);
}

- (void)configItem:(ZHDPOptionItem *)item{
    self.label.text = [NSString stringWithFormat:@"%@", item.showTitle];
    self.label.font = item.font;
    self.label.textColor = item.isSelected ? [ZHDPMg() selectColor] : [ZHDPMg() defaultColor];
    self.label.backgroundColor = item.isSelected ? [UIColor colorWithRed:12.0/255.0 green:200.0/255.0 blue:46.0/255.0 alpha:0.05] : [ZHDPMg() bgColor];
}
- (void)configLine:(BOOL)hide{
    self.line.hidden = hide;
}
- (void)configCornerRadius:(CGFloat)radius{
    self.clipsToBounds = YES;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = radius;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.adjustsFontSizeToFitWidth = YES;
    }
    return _label;
}
- (UIView *)line{
    if (!_line) {
        _line = [[UIView alloc] initWithFrame:CGRectZero];
        _line.backgroundColor = [ZHDPMg() defaultLineColor];
    }
    return _line;
}

@end

@interface ZHDPOptionExpan ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, assign) BOOL syncUpdateFrame;
@property (nonatomic, strong) UIButton *bgBtn;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, retain) NSArray <ZHDPOptionItem *> *items;
@property (nonatomic,strong) ZHDPOptionItem *selectItem;
@end
@implementation ZHDPOptionExpan

#pragma mark - override

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configData];
        [self configUI];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    
    if (!self.syncUpdateFrame) return;
    
    self.bgBtn.frame = self.bounds;
    
    CGFloat W = self.bounds.size.width;
    CGFloat Y = 0;
    CGFloat H = self.bounds.size.height * [self bgViewScaleH];
    CGFloat X = 0;
    self.bgView.frame = CGRectMake(X, Y, W, H);
    
    [self updateCollectionViewFrame];
        
    [self reloadCollectionViewFrequently];
}

#pragma mark - frame

- (void)updateCollectionViewFrame{
    CGFloat Y = 10;
    CGFloat H = self.bgView.bounds.size.height - 2 * Y;
    CGFloat X = 10;
    CGFloat W = self.bgView.bounds.size.width - 2 * X;
    self.collectionView.frame = CGRectMake(X, Y, W, H >= 0 ? H : 0);
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.bgBtn];
    [self addSubview:self.bgView];
    [self.bgView addSubview:self.collectionView];
    
    self.bgView.clipsToBounds = YES;
    self.bgView.layer.masksToBounds = YES;
    self.bgView.layer.cornerRadius = [ZHDPMg() defaultCornerRadius];
}

#pragma mark - show

- (void)showOptionExpan:(UIView *)inView items:(NSArray <ZHDPOptionItem *> *)items{
    if (!inView || self.superview) {
        return;
    }
    self.syncUpdateFrame = NO;
    
    [inView addSubview:self];
    self.frame = inView.bounds;
    self.bgBtn.frame = self.bounds;
    self.bgView.frame = CGRectMake(0, -self.bounds.size.height * [self bgViewScaleH], self.bounds.size.width, self.bounds.size.height * [self bgViewScaleH]);
    [self updateCollectionViewFrame];
    
    [self reloadWithItems:items];
    
    self.bgBtn.alpha = 0.0;
    [ZHDPMg() doAnimation:^{
        self.bgBtn.alpha = 0.3;
        self.bgView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height * [self bgViewScaleH]);
    } completion:^(BOOL finished) {
        self.syncUpdateFrame = YES;
    }];
}
- (void)hideOptionExpan{
    [ZHDPMg() doAnimation:^{
        self.bgBtn.alpha = 0.0;
        self.bgView.frame = CGRectMake(0, -self.bounds.size.height * [self bgViewScaleH], self.bounds.size.width, self.bounds.size.height * [self bgViewScaleH]);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        self.syncUpdateFrame = NO;
    }];
}
- (CGFloat)bgViewScaleH{
    return 0.5;
}

#pragma mark - click

- (void)bgBtnClick:(UIButton *)btn{
    [self.debugPanel.option hideOptionExpan];
}

#pragma mark - relaod

- (void)reloadCollectionViewFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadCollectionView) object:nil];
    [self performSelector:@selector(reloadCollectionView) withObject:nil afterDelay:0.3];
}
- (void)reloadCollectionView{
    [self.collectionView reloadData];
}
- (void)reloadWithItems:(NSArray <ZHDPOptionItem *> *)items{
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return;
    }
    for (id item in items) {
        if (![item isKindOfClass:ZHDPOptionItem.class]) {
            return;
        }
    }
    self.items = items.copy;
    [self reloadCollectionView];
}

#pragma mark - select

- (void)selectItem:(ZHDPOptionItem *)item{
    if (![self.items containsObject:item]) return;
    NSUInteger idx = [self.items indexOfObject:item];
    [self selectIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
}
- (void)selectIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= self.items.count) return;
    
    for (NSUInteger i = 0; i < self.items.count; i++) {
        self.items[i].selected = (indexPath.item == i ? YES : NO);
    }
    self.selectItem = self.items[indexPath.item];
    if (self.selectBlock) self.selectBlock(indexPath, self.selectItem);
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
    [self reloadCollectionView];
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZHDPOptionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.collectionCellIdentifier forIndexPath:indexPath];
    ZHDPOptionItem *item = self.items[indexPath.item];
    [cell configItem:item];
    [cell configLine:YES];
    [cell configCornerRadius:5.0];
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPOptionItem *item = self.items[indexPath.item];
    CGFloat fitWidth = [item.showTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.frame.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: item.font} context:nil].size.width;
    return CGSizeMake(fitWidth + 2 * 8, 30);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self selectIndexPath:indexPath];
}

#pragma mark - getter

- (UIButton *)bgBtn{
    if (!_bgBtn) {
        _bgBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        _bgBtn.backgroundColor = [UIColor blackColor];
        [_bgBtn addTarget:self action:@selector(bgBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bgBtn;
}
- (UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:CGRectZero];
        _bgView.backgroundColor = [UIColor whiteColor];
    }
    return _bgView;
}
- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 5;
        layout.minimumLineSpacing = 5;// 横向间距
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
                
//        [Assert] negative or zero item sizes are not supported in the flow layout
        layout.itemSize = CGSizeMake(1, 1);
        
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = YES;
        _collectionView.alwaysBounceHorizontal = NO;
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.directionalLockEnabled = YES;
        
        [_collectionView registerClass:[ZHDPOptionCollectionViewCell class] forCellWithReuseIdentifier:self.collectionCellIdentifier];
    }
    return _collectionView;
}
- (NSString *)collectionCellIdentifier{
    return [NSString stringWithFormat:@"%@_CollectionViewCell", NSStringFromClass(self.class)];
}
@end


@interface ZHDPOption ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic,strong) UIView *line;

@property (nonatomic,strong) UIButton *hideBtn;
@property (nonatomic,strong) UIButton *menuBtn;
@property (nonatomic,strong) UIView *rightLine;

@property (nonatomic, strong) UIPanGestureRecognizer *panGes;
@property (nonatomic, assign) CGPoint gesStartPoint;
@property (nonatomic, assign) CGRect gesStartFrame;
@end

@implementation ZHDPOption

#pragma mark - override

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configData];
        [self configUI];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat W = 40;
    CGFloat H = self.bounds.size.height;
    CGFloat Y = 0;
    CGFloat X = self.bounds.size.width - W;
    self.hideBtn.frame = CGRectMake(X, Y, W, H);
    
    W = 30;
    H = self.bounds.size.height;
    X = self.hideBtn.frame.origin.x - W;
    Y = 0;
    self.menuBtn.frame = CGRectMake(X, Y, W, H);
    
    X = 0;
    W = [ZHDPMg() defaultLineW];
    H = self.hideBtn.frame.size.height;
    Y = 0;
    self.rightLine.frame = CGRectMake(X, Y, W, H);
    
    X = 0;
    Y = 0;
    W = self.menuBtn.frame.origin.x - X;
    H = self.bounds.size.height;
//    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
//    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
//        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(80, H);
//    }
    self.collectionView.frame = CGRectMake(X, Y, W, H);
    
    X = 0;
    W = self.bounds.size.width;
    H = [ZHDPMg() defaultLineW];
    Y = self.bounds.size.height - H;
    self.line.frame = CGRectMake(X, Y, W, H);

    [self reloadCollectionViewFrequently];
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    [self addGesture];
    
    [self addSubview:self.collectionView];
    [self addSubview:self.line];
    [self addSubview:self.hideBtn];
    [self addSubview:self.menuBtn];
    [self.menuBtn addSubview:self.rightLine];
}

#pragma mark - gesture

- (void)addGesture{
    self.panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self addGestureRecognizer:self.panGes];
}
- (void)panGesture:(UIPanGestureRecognizer *)panGes{
    UIView *superview = self.debugPanel.superview;
//    CGFloat superW = superview.frame.size.width;
//    CGFloat superH = superview.frame.size.height;
    
    if (panGes.state == UIGestureRecognizerStateBegan) {
        self.gesStartPoint = [panGes locationInView:superview];
        self.gesStartFrame = self.debugPanel.frame;
    } else if (panGes.state == UIGestureRecognizerStateChanged){

//        CGPoint velocity = [panGes velocityInView:superview];
        CGPoint p = [panGes locationInView:superview];
//        CGFloat offsetX = p.x - self.gesStartPoint.x;
        CGFloat offSetY = p.y - self.gesStartPoint.y;
        
        CGFloat X = self.gesStartFrame.origin.x;
        CGFloat Y = self.gesStartFrame.origin.y + offSetY;
        CGFloat W = self.gesStartFrame.size.width;
        CGFloat H = self.gesStartFrame.size.height - offSetY;
        
        [ZHDPMg().window updateDebugPanelFrame:CGRectMake(X, Y, W, H)];
        
    } else if (panGes.state == UIGestureRecognizerStateEnded ||
               panGes.state == UIGestureRecognizerStateCancelled ||
               panGes.state == UIGestureRecognizerStateFailed){
    }
}

#pragma mark - relaod

- (void)reloadCollectionViewFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadCollectionView) object:nil];
    [self performSelector:@selector(reloadCollectionView) withObject:nil afterDelay:0.3];
}
- (void)reloadCollectionView{
    [self.collectionView reloadData];
}
- (void)reloadWithItems:(NSArray <ZHDPOptionItem *> *)items{
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return;
    }
    for (id item in items) {
        if (![item isKindOfClass:ZHDPOptionItem.class]) {
            return;
        }
    }
    self.items = items.copy;
    [self reloadCollectionView];
}

#pragma mark - select

- (void)selectItem:(ZHDPOptionItem *)item{
    if (![self.items containsObject:item]) return;
    NSUInteger idx = [self.items indexOfObject:item];
    [self selectIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
}
- (void)selectIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.item >= self.items.count) return;
    
    for (NSUInteger i = 0; i < self.items.count; i++) {
        self.items[i].selected = (indexPath.item == i ? YES : NO);
    }
    self.selectItem = self.items[indexPath.item];
    if (self.selectBlock) self.selectBlock(indexPath, self.selectItem);
    [self hideOptionExpan];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    [self reloadCollectionView];
}
- (void)selectListClass:(Class)listClass{
    if (self.items.count <= 0 || !listClass) {
        return;
    }
    ZHDPOptionItem *targetItem = nil;
    NSArray *items = self.items.copy;
    for (ZHDPOptionItem *item in items) {
        if ([item.list isKindOfClass:listClass]) {
            targetItem = item;
            break;
        }
    }
    [self selectItem:targetItem];
}

#pragma mark - click

- (void)hideBtnClick:(UIButton *)btn{
    [ZHDPMg() switchFloat];
}
- (void)menuBtnClick:(UIButton *)btn{
    BOOL expan = !btn.isSelected;
    if (expan) {
        [self.debugPanel showOptionExpan:self.items];
    }else{
        [self.debugPanel hideOptionExpan];
    }
    btn.selected = expan;
}
- (void)hideOptionExpan{
    if (self.menuBtn.isSelected) {
        [self menuBtnClick:self.menuBtn];
    }
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZHDPOptionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.collectionCellIdentifier forIndexPath:indexPath];
    ZHDPOptionItem *item = self.items[indexPath.item];
    [cell configItem:item];
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPOptionItem *item = self.items[indexPath.item];
    CGFloat fitWidth = [item.showTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.frame.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: item.font} context:nil].size.width;
    return CGSizeMake(fitWidth + 2 * 8, self.bounds.size.height);
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
        layout.minimumLineSpacing = 0;// 横向间距
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                
//        [Assert] negative or zero item sizes are not supported in the flow layout
        layout.itemSize = CGSizeMake(1, 1);
        
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _collectionView.showsHorizontalScrollIndicator = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.alwaysBounceVertical = NO;
        _collectionView.directionalLockEnabled = YES;
        
        [_collectionView registerClass:[ZHDPOptionCollectionViewCell class] forCellWithReuseIdentifier:self.collectionCellIdentifier];
    }
    return _collectionView;
}
- (NSString *)collectionCellIdentifier{
    return [NSString stringWithFormat:@"%@_CollectionViewCell", NSStringFromClass(self.class)];
}
- (UIView *)line{
    if (!_line) {
        _line = [[UIView alloc] initWithFrame:CGRectZero];
        _line.backgroundColor = [ZHDPMg() defaultLineColor];
    }
    return _line;
}
- (UIButton *)hideBtn{
    if (!_hideBtn) {
        _hideBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        _hideBtn.titleLabel.font = [ZHDPMg() iconFontWithSize:20];
        
        [_hideBtn setTitle:@"\ue60c" forState:UIControlStateNormal];
        [_hideBtn setTitleColor:[ZHDPMg() defaultColor] forState:UIControlStateNormal];
        
        [_hideBtn addTarget:self action:@selector(hideBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hideBtn;
}
- (UIButton *)menuBtn{
    if (!_menuBtn) {
        _menuBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        _menuBtn.titleLabel.font = [ZHDPMg() iconFontWithSize:20];
        
        [_menuBtn setTitle:@"\ue600" forState:UIControlStateNormal];
        [_menuBtn setTitle:@"\ueb6b" forState:UIControlStateSelected];
        [_menuBtn setTitleColor:[ZHDPMg() defaultColor] forState:UIControlStateNormal];
        [_menuBtn setTitleColor:[ZHDPMg() selectColor] forState:UIControlStateSelected];
        
        [_menuBtn addTarget:self action:@selector(menuBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _menuBtn;
}
- (UIView *)rightLine{
    if (!_rightLine) {
        _rightLine = [[UIView alloc] initWithFrame:CGRectZero];
        _rightLine.backgroundColor = [ZHDPMg() defaultLineColor];
    }
    return _rightLine;
}

@end
