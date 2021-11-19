//
//  ZHDPListPop.m
//  ZHJSNative
//
//  Created by EM on 2021/5/29.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListPop.h"
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPList.h"// 列表

@interface ZHDPListPop ()
@property (nonatomic, strong) UIPanGestureRecognizer *panGes;
@property (nonatomic, assign) CGPoint gesStartPoint;
@property (nonatomic, assign) CGRect gesStartFrame;

@property (nonatomic, assign) BOOL popShow;
@end
@implementation ZHDPListPop

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
    
    self.bgBtn.frame = self.list.bounds;
    self.shadowView.frame = self.bounds;
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    BOOL show = self.superview;
    if (!show) return;
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
}

// 子类重写
- (CGFloat)defaultPopW{
    return 85;
}
- (CGFloat)minPopW{
    return 50;
}
- (CGFloat)maxPopW{
    return self.list.bounds.size.width - 10;
}
- (void)updateFrameX:(BOOL)hide{
    CGFloat superW = self.list.bounds.size.width;
    CGFloat superH = self.list.bounds.size.height;
    CGFloat selfW = self.frame.size.width;
    CGFloat selfH = self.frame.size.height;
    
    CGFloat W = selfW > 0 ? selfW : [self defaultPopW];
    CGFloat X = hide ? superW : superW - W;
    CGFloat H = selfH > 0 ? selfH : superH;
    CGFloat Y = (superH - H) * 0.5;
    self.frame = CGRectMake(X, Y, W, H);
}
- (void)updateFrameH{    
    CGFloat superH = self.list.bounds.size.height;
    
    CGFloat W = self.frame.size.width;
    CGFloat X = self.frame.origin.x;
    CGFloat H = superH * 1.0;
    CGFloat Y = (superH - H) * 0.5;
    self.frame = CGRectMake(X, Y, W, H);
}
- (void)show{
    self.popShow = YES;
    
    [self.bgBtn removeFromSuperview];
    if ([self allowMaskWhenShow]) {
        [self.list insertSubview:self.bgBtn belowSubview:self];
        self.bgBtn.alpha = 0.0;
        [ZHDPMg() doAnimation:^{
            self.bgBtn.alpha = 0.3;
        } completion:^(BOOL finished) {
            
        }];
    }
}
- (void)hide{
    self.popShow = NO;
    
    [ZHDPMg() doAnimation:^{
        self.bgBtn.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.bgBtn removeFromSuperview];
    }];
}
- (BOOL)allowMaskWhenShow{
    return YES;
}
- (void)reloadList{
}

- (BOOL)isShow{
    return self.popShow;
}
- (void)reloadListInstant{
    [self reloadList];
}
- (void)reloadListFrequently{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadList) object:nil];
    [self performSelector:@selector(reloadList) withObject:nil afterDelay:0.25];
}

#pragma mark - config

- (void)configUI{
//    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    
    [self addGesture];
    
    [self addSubview:self.shadowView];
}

#pragma mark - frame

#pragma mark - click

- (void)bgBtnClick:(UIButton *)btn{
    if ([self isShow]) {
        [self hide];
    }else{
        [self show];
    }
}

#pragma mark - gesture

- (void)addGesture{
    self.panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self addGestureRecognizer:self.panGes];
}
- (void)panGesture:(UIPanGestureRecognizer *)panGes{
    UIView *superview = self.superview;
    CGFloat superW = superview.frame.size.width;
//    CGFloat superH = superview.frame.size.height;
    __weak __typeof__(self) weakSelf = self;
    
    if (panGes.state == UIGestureRecognizerStateBegan) {
        self.gesStartPoint = [panGes locationInView:superview];
        self.gesStartFrame = self.frame;
    } else if (panGes.state == UIGestureRecognizerStateChanged){

//        CGPoint velocity = [panGes velocityInView:superview];
//        NSLog(@"%.f",velocity.x);
        CGPoint p = [panGes locationInView:superview];
        CGFloat offsetX = p.x - self.gesStartPoint.x;
//        CGFloat offSetY = p.y - self.gesStartPoint.y;
                
        CGFloat cWidth = self.gesStartFrame.size.width + (-offsetX);
        if (cWidth <= [self minPopW]) cWidth = [self minPopW];
        if (cWidth >= [self maxPopW]) cWidth = [self maxPopW];
        
        self.frame = (CGRect){{CGRectGetMaxX(self.gesStartFrame) - cWidth, self.gesStartFrame.origin.y}, {cWidth, self.gesStartFrame.size.height}};
        
    } else if (panGes.state == UIGestureRecognizerStateEnded ||
               panGes.state == UIGestureRecognizerStateCancelled ||
               panGes.state == UIGestureRecognizerStateFailed){
    }
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
- (ZHDPListPopShadow *)shadowView{
    if (!_shadowView) {
        _shadowView = [[ZHDPListPopShadow alloc] initWithFrame:CGRectZero];
    }
    return _shadowView;
}

@end
