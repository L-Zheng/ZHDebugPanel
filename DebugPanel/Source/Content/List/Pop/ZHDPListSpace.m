//
//  ZHDPListSpace.m
//  ZHDebugPanel
//
//  Created by EM on 2022/1/20.
//

#import "ZHDPListSpace.h"
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPList.h"// 列表
#import "ZHDPStorageManager.h"

@interface ZHDPListSpace () <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic,strong) UILabel *topTipLabel;
@property (nonatomic,strong) UIButton *cancelBtn;
@property (nonatomic,strong) UIButton *sureBtn;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,retain) NSArray <ZHDPListSpaceItem *> *items;
@property (nonatomic,strong) UIPickerView *pickerView;
@property (nonatomic,retain) NSArray *pickerItems;

@property (nonatomic,strong) ZHDPListSpaceItem *selectItem;
@end

@implementation ZHDPListSpace

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
    
    CGFloat X = self.shadowView.frame.origin.x;
    CGFloat Y = 0;
    CGFloat W = self.shadowView.frame.size.width;
    CGFloat H = 44;
    self.topTipLabel.frame = CGRectMake(X, Y, W, H);
    
    X = self.shadowView.frame.origin.x;
    Y = self.shadowView.frame.size.height - H;
    W = self.shadowView.frame.size.width * 0.5;
    self.cancelBtn.frame = CGRectMake(X, Y, W, H);
    
    X = CGRectGetMaxX(self.cancelBtn.frame);
    Y = self.shadowView.frame.size.height - H;
    W = self.shadowView.frame.size.width * 0.5;
    self.sureBtn.frame = CGRectMake(X, Y, W, H);
    
    CGFloat splitScale = 0.6;
    
    X = self.shadowView.frame.origin.x;
    Y = CGRectGetMaxY(self.topTipLabel.frame);
    W = self.shadowView.frame.size.width * splitScale;
    H = self.shadowView.frame.size.height - Y - H;
    self.tableView.frame = CGRectMake(X, Y, W, H);
    
    X = CGRectGetMaxX(self.tableView.frame);
    Y = CGRectGetMaxY(self.topTipLabel.frame);
    W = self.shadowView.frame.size.width * (1 - splitScale);
    self.pickerView.frame = CGRectMake(X, Y, W, H);
    
    [self reloadListFrequently];
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
//    BOOL show = self.superview;
//    if (!show) return;
}

- (CGFloat)defaultPopW{
    return 300;
}
- (CGFloat)minPopW{
    return 200;
}
- (CGFloat)maxPopW{
    return self.list.bounds.size.width - 20;
}
- (void)show{
    [ZHDPMg().window enableDebugPanel:NO];
    if ([self isShow]) {
        [ZHDPMg().window enableDebugPanel:YES];
        return;
    }
    
    [self updateFrameX:YES];
    [self.list addSubview:self];
    [self reloadSpaceItems];
    
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
        [self removeFromSuperview];
        [ZHDPMg().window enableDebugPanel:YES];
    }];
}
- (BOOL)allowMaskWhenShow{
    return YES;
}
- (void)reloadList{
    [self.tableView reloadData];
    [self.pickerView reloadAllComponents];
}

#pragma mark - config

- (void)configUI{
    [super configUI];
    [self addSubview:self.topTipLabel];
    [self addSubview:self.tableView];
    [self addSubview:self.pickerView];
    [self addSubview:self.cancelBtn];
    [self addSubview:self.sureBtn];
}

#pragma mark - data

- (void)reloadSpaceItems{
    NSArray <ZHDPDataSpaceItem *> *spaces = [ZHDPMg().dataTask fetchSpaceItems];
    
    NSMutableArray *res = [NSMutableArray array];
    for (NSUInteger i = 0; i < spaces.count; i++) {
        ZHDPListSpaceItem *spaceItem = [[ZHDPListSpaceItem alloc] init];
        spaceItem.dataSpaceItem = spaces[i];
        spaceItem.title = spaceItem.dataSpaceItem.title;
        spaceItem.count = spaceItem.dataSpaceItem.count;
        
        NSMutableArray *canSelectValues = [NSMutableArray array];
        for (NSInteger j = -10; j < 20; j++) {
            NSInteger value = spaceItem.dataSpaceItem.count + j * 50;
            if (value > 0) {
                [canSelectValues addObject:@(value)];
            }
        }
        spaceItem.canSelectValues = canSelectValues.copy;
        __weak __typeof__(spaceItem) weakSpaceItem = spaceItem;
        spaceItem.block = ^(NSInteger count) {
            [ZHDPStorageMg() updateConfig_max:weakSpaceItem.dataSpaceItem.storeKey count:count];
            weakSpaceItem.dataSpaceItem.count = count;
        };
        [res addObject:spaceItem];
    }
    self.items = res.copy;
    [self selectIdx:0];
}

#pragma mark - select

- (void)selectIdx:(NSUInteger)idx{
    if (idx >= self.items.count) return;
    [self selectItem:self.items[idx]];
}
- (void)selectItem:(ZHDPListSpaceItem *)item{
    if (!item) return;
    
    for (ZHDPListSpaceItem *item in self.items) {
        item.selected = NO;
    }
    item.selected = YES;
    self.selectItem = item;
    
    // 刷新picker
    self.pickerItems = @[@"载入..."];
    [self reloadListInstant];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (item.canSelectValues.count <= 0) return;
            
        // 加载picker数据
        self.pickerItems = item.canSelectValues;
        [self reloadListInstant];
        
        // 滚动到指定位置
        NSUInteger selectIdx = NSNotFound;
        for (NSUInteger i = 0; i < self.pickerItems.count; i++) {
            NSNumber *num = self.pickerItems[i];
            if (num.integerValue == item.count) {
                selectIdx = i;
                break;
            }
        }
        [self.pickerView selectRow:(selectIdx == NSNotFound ? 0 : selectIdx) inComponent:0 animated:YES];
        [self selectPicker:selectIdx];
    });
}
- (void)selectPicker:(NSInteger)idx{
    if (idx >= self.pickerItems.count) {
        return;
    }
    NSNumber *value = self.pickerItems[idx];
    if ([value isKindOfClass:NSNumber.class]) {
        self.selectItem.count = value.integerValue;
        [self.tableView reloadData];
    }
}

#pragma mark - click

- (void)cancelBtnClick:(UIButton *)btn{
    [self hide];
}
- (void)sureBtnClick:(UIButton *)btn{
    for (ZHDPListSpaceItem *item in self.items) {
        void (^block) (NSInteger count) = item.block;
        if (block) {
            block(item.count);
        }
    }
    [self hide];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.items.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellID = [NSString stringWithFormat:@"%@_UITableViewCell", NSStringFromClass(self.class)];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        // >=xcode13以上编译
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
        if (@available(iOS 14.0, *)) {
            cell.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration];
        }
#endif
        cell.clipsToBounds = YES;
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundView = [UIView new];
        
        cell.textLabel.font = [ZHDPMg() defaultFont];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }
    ZHDPListSpaceItem *item = self.items[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ [%ld条]", item.title, item.count];
    cell.textLabel.textColor = item.isSelected ? [ZHDPMg() selectColor] : [ZHDPMg() defaultColor];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self selectIdx:indexPath.row];
}

#pragma mark - UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return self.pickerItems.count;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    [self selectPicker:row];
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [NSString stringWithFormat:@"%@", self.pickerItems[row]];
}

#pragma mark - getter

- (UILabel *)topTipLabel {
    if (!_topTipLabel) {
        _topTipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _topTipLabel.font = [ZHDPMg() defaultBoldFont];
        _topTipLabel.textAlignment = NSTextAlignmentCenter;
        _topTipLabel.text = @"调整日志最大收集量";
        _topTipLabel.textColor = [UIColor blackColor];
        _topTipLabel.backgroundColor = [UIColor clearColor];
        _topTipLabel.adjustsFontSizeToFitWidth = NO;
    }
    return _topTipLabel;
}
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        // >=xcode13以上编译
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
        if (@available(iOS 15.0, *)){
            _tableView.sectionHeaderTopPadding = 0;
        }
#endif
        
        _tableView.directionalLockEnabled = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        _tableView.layer.borderColor = [ZHDPMg() defaultLineColor].CGColor;
        _tableView.layer.borderWidth = [ZHDPMg() defaultLineW];
        
        _tableView.separatorInset = UIEdgeInsetsZero;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    return _tableView;
}
- (UIPickerView *)pickerView{
    if (!_pickerView) {
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
        _pickerView.delegate = self;
        _pickerView.dataSource = self;
        
        _pickerView.layer.borderColor = [ZHDPMg() defaultLineColor].CGColor;
        _pickerView.layer.borderWidth = [ZHDPMg() defaultLineW];
    }
    return _pickerView;
}
- (UIButton *)cancelBtn{
    if (!_cancelBtn) {
        _cancelBtn = [self createBtn:@"取消" action:@selector(cancelBtnClick:)];
    }
    return _cancelBtn;
}
- (UIButton *)sureBtn{
    if (!_sureBtn) {
        _sureBtn = [self createBtn:@"确定" action:@selector(sureBtnClick:)];
    }
    return _sureBtn;
}
- (UIButton *)createBtn:(NSString *)title action:(SEL)action{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectZero];
    btn.backgroundColor = [UIColor clearColor];
    btn.titleLabel.font = [ZHDPMg() defaultBoldFont];
    btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}
@end
