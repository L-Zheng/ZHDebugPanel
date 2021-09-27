//
//  ZHDPToast.m
//  Pods-Demo
//
//  Created by EM on 2021/9/26.
//

#import "ZHDPToast.h"
#import "ZHDPManager.h"

@interface ZHDPToast ()
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic,strong) UILabel *label;
@property (nonatomic,strong) NSValue *startFrameValue;
@end

@implementation ZHDPToast

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

#pragma mark - config

- (void)configData{
}
- (void)configUI{
//    self.backgroundColor = [UIColor orangeColor];
    [self addSubview:self.bgView];
    [self.bgView addSubview:self.label];
}

#pragma mark - action

- (void)clickBgView{
    if (self.clickBlock) self.clickBlock();
    [self startHide];
}
- (void)show{
    NSString *title = self.title;
    if (!title || ![title isKindOfClass:NSString.class] || title.length == 0) {
        return;
    }
    NSString *colorStr = [ZHDPOutputItem colorStrByType:self.outputType];
    self.label.textColor = colorStr ? [ZHDPMg() zhdp_colorFromHexString:colorStr] : [ZHDPMg() selectColor];
    self.label.text = title;
    
    UIView *container = self.debugPanel;
    
    CGSize size = [title boundingRectWithSize:CGSizeMake(container.bounds.size.width - 10, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.label.font} context:nil].size;
    size.width += 10;
    size.height += 10;
    if (size.width < 150) size.width = 150;
    if (size.height < 30) size.height = 30;
    
    CGFloat X = (container.bounds.size.width - size.width) * 0.5;
    
    CGRect startFrame = (CGRect){{X, -size.height}, size};
    CGRect endFrame = (CGRect){{X, 5}, size};
    
    [container addSubview:self];
    self.frame = startFrame;
    self.bgView.frame = self.bounds;
    self.label.frame = self.bgView.bounds;
    
    // 设置圆角阴影
    self.bgView.clipsToBounds = YES;
    self.bgView.layer.masksToBounds = YES;
    self.bgView.layer.cornerRadius = self.frame.size.height * 0.5;
    
    CALayer *subLayer = [CALayer layer];
    subLayer.frame = self.bgView.frame;
    subLayer.cornerRadius = self.bgView.frame.size.height * 0.5;
    subLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
    subLayer.masksToBounds = NO;
    subLayer.shadowColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
    subLayer.shadowOffset = CGSizeMake(0, 6.f);
    subLayer.shadowOpacity = 0.5;
    subLayer.shadowRadius = 10.f;
    [self.layer insertSublayer:subLayer below:self.bgView.layer];
    
    self.startFrameValue = [NSValue valueWithCGRect:startFrame];
    
    [UIView animateWithDuration:self.animateDuration animations:^{
        self.frame = endFrame;
    } completion:^(BOOL finished) {
        if (self.showComplete) self.showComplete();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.stayDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startHide];
        });
    }];
}
- (void)startHide{
    if (!self.startFrameValue) return;
    
    CGRect startFrame = self.startFrameValue.CGRectValue;
    self.startFrameValue = nil;
    
    [UIView animateWithDuration:self.animateDuration animations:^{
        self.frame = startFrame;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    if (self.hideComplete) self.hideComplete();
}

#pragma mark - getter

- (UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:CGRectZero];
        _bgView.backgroundColor = [UIColor whiteColor];
        _bgView.clipsToBounds = YES;
        UIGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickBgView)];
        [_bgView addGestureRecognizer:tapGes];
    }
    return _bgView;
}
- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.font = [ZHDPMg() defaultFont];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.numberOfLines = 0;
    }
    return _label;
}

@end
