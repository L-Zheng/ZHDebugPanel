//
//  ZHDPFilter.m
//  Pods-Demo
//
//  Created by EM on 2021/9/9.
//

#import "ZHDPFilter.h"
#import "ZHDPManager.h"

@interface ZHDPFilter ()
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UILabel *tipLabel;
@property (nonatomic,strong) UIButton *selectAllBtn;
@end

@implementation ZHDPFilter

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
    self.tableView.frame = self.bounds;
    self.selectAllBtn.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 44);
    self.tipLabel.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 44);
    
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

#pragma mark - reload

- (void)reloadListInstant{
    self.tableView.tableHeaderView = (self.items.count > 0 ? self.selectAllBtn : [UIView new]);
    self.tableView.tableFooterView = (self.items.count <= 0 ? self.tipLabel : [UIView new]);
    [self.tableView reloadData];
}
- (void)reloadListFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadListInstant) object:nil];
    [self performSelector:@selector(reloadListInstant) withObject:nil afterDelay:0.25];
}

#pragma mark - config

- (void)configData{
}
- (void)configUI{
    [self addSubview:self.tableView];
}

#pragma mark - click

- (void)selectAllBtnClick{
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
        cell.clipsToBounds = YES;
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundView = [UIView new];
        
        cell.textLabel.font = [ZHDPMg() defaultFont];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }
    return cell;
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        
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
- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _tipLabel.font = [ZHDPMg() defaultFont];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.text = @"内容为空";
        _tipLabel.numberOfLines = 0;
        _tipLabel.textColor = [UIColor blackColor];
        _tipLabel.backgroundColor = [UIColor clearColor];
        _tipLabel.adjustsFontSizeToFitWidth = NO;
    }
    return _tipLabel;
}
- (UIButton *)selectAllBtn{
    if (!_selectAllBtn) {
        _selectAllBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        _selectAllBtn.backgroundColor = [UIColor clearColor];
        _selectAllBtn.titleLabel.font = [ZHDPMg() defaultFont];
        _selectAllBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        
        _selectAllBtn.layer.borderColor = [ZHDPMg() defaultLineColor].CGColor;
        _selectAllBtn.layer.borderWidth = [ZHDPMg() defaultLineW];
        
        [_selectAllBtn setTitle:@"选择全部" forState:UIControlStateNormal];
        [_selectAllBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        [_selectAllBtn addTarget:self action:@selector(selectAllBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectAllBtn;
}

@end
