//
//  ZHDPListToolsView.m
//  Pods-Demo
//
//  Created by EM on 2022/1/21.
//

#import "ZHDPListToolsView.h"
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPList.h"

@interface ZHDPListToolCollectionViewCell()
@property (nonatomic,strong) UIView *selectView;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) UILabel *descLabel;
@end
@implementation ZHDPListToolCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configNormalStyle];
        
        self.selectedBackgroundView = self.selectView;
        [self.contentView addSubview:self.iconLabel];
        [self.contentView addSubview:self.descLabel];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    BOOL titleHide = self.descLabel.isHidden;
    
    CGFloat X = 0;
    CGFloat Y = 0;
    CGFloat W = self.bounds.size.width;
    CGFloat H = 30;
    self.iconLabel.frame = titleHide ? self.bounds : CGRectMake(X, Y, W, H);
//    self.iconLabel.backgroundColor = [UIColor cyanColor];
    
    X = 0;
    W = self.bounds.size.width;
    H = 25;
    Y = self.bounds.size.height - H;
    self.descLabel.frame = titleHide ? CGRectZero : CGRectMake(X, Y, W, H);
//    self.descLabel.backgroundColor = [UIColor orangeColor];
}

- (void)configItem:(ZHDPListToolItem *)item{
    self.iconLabel.text = item.icon;
    self.descLabel.text = item.desc;
    self.iconLabel.textColor = item.isSelected ? [ZHDPMg() selectColor] : [ZHDPMg() defaultColor];
    self.descLabel.textColor = self.iconLabel.textColor;
    [self configTitleHideEnable:NO];
}

- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    (selected ? [self configHighlightStyle] : [self configNormalStyle]);
}
- (void)configTitleHideEnable:(BOOL)enable{
    self.descLabel.hidden = enable;
}
- (void)configNormalStyle{
    self.contentView.backgroundColor = [UIColor clearColor];
//    cell.contentView.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255.0)/255.0 green:arc4random_uniform(255.0)/255.0 blue:arc4random_uniform(255.0)/255.0 alpha:0.5];
}
- (void)configHighlightStyle{
    self.contentView.backgroundColor = [UIColor lightGrayColor];
}

- (UIView *)selectView{
    if (!_selectView) {
        _selectView = [[UIView alloc] initWithFrame:CGRectZero];
        _selectView.clipsToBounds = YES;
    }
    return _selectView;
}
- (UILabel *)iconLabel {
    if (!_iconLabel) {
        _iconLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _iconLabel.font = [ZHDPMg() iconFontWithSize:20];
        _iconLabel.textAlignment = NSTextAlignmentCenter;
//        _iconLabel.numberOfLines = 0;
        _iconLabel.backgroundColor = [UIColor clearColor];
        _iconLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _iconLabel;
}
- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _descLabel.font = [ZHDPMg() defaultFont];
        _descLabel.textAlignment = NSTextAlignmentCenter;
//        _descLabel.numberOfLines = 0;
        _descLabel.backgroundColor = [UIColor clearColor];
        _descLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _descLabel;
}

@end

@interface ZHDPListToolsView ()
@end

@implementation ZHDPListToolsView

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
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
//    BOOL show = self.superview;
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.collectionView];
}

#pragma mark - reload

- (void)reloadCollectionViewFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadCollectionView) object:nil];
    [self performSelector:@selector(reloadCollectionView) withObject:nil afterDelay:0.3];
}
- (void)reloadCollectionView{
    [self.collectionView reloadData];
}
- (void)reloadWithItems:(NSArray <ZHDPListToolItem *> *)items{
    if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
        return;
    }
    for (id item in items) {
        if (![item isKindOfClass:ZHDPListToolItem.class]) {
            return;
        }
    }
    self.items = items.copy;
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
    ZHDPListToolCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.collectionCellIdentifier forIndexPath:indexPath];
    [cell configItem:self.items[indexPath.item]];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    void (^block) (void) = self.items[indexPath.item].block;
    if (block) block();
}
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPListToolCollectionViewCell *cell = (ZHDPListToolCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell configHighlightStyle];
}
- (void)collectionView:(UICollectionView *)collectionView  didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    ZHDPListToolCollectionViewCell *cell = (ZHDPListToolCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell configNormalStyle];
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
        
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.alwaysBounceVertical = NO;
        _collectionView.directionalLockEnabled = YES;
//        _collectionView.pagingEnabled = YES;
        
        [_collectionView registerClass:[ZHDPListToolCollectionViewCell class] forCellWithReuseIdentifier:self.collectionCellIdentifier];
    }
    return _collectionView;
}
- (NSString *)collectionCellIdentifier{
    return [NSString stringWithFormat:@"%@_CollectionViewCell", NSStringFromClass(self.class)];
}
@end
