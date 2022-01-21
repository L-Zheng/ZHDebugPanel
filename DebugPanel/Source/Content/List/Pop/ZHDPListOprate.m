//
//  ZHDPListOprate.m
//  ZHJSNative
//
//  Created by EM on 2021/5/28.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListOprate.h"
#import "ZHDPList.h"// 列表
#import "ZHDPManager.h"// 调试面板管理
#import "ZHDPListApps.h"// pop app列表
#import "ZHDPListOprateOption.h" // 操作栏

@interface ZHDPListOprate ()
@property (nonatomic, strong) ZHDPListOprateOption *option;
@end

@implementation ZHDPListOprate

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
    
    self.option.frame = self.shadowView.frame;
    
    CGFloat W = [self minPopW] * 0.5;
    CGFloat H = W;
    UICollectionViewLayout *layout = self.option.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:UICollectionViewFlowLayout.class]) {
        ((UICollectionViewFlowLayout *)layout).itemSize = CGSizeMake(W, H);
    }
    self.option.collectionView.frame = self.shadowView.frame;
    [self reloadListFrequently];
}
- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
//    BOOL show = self.superview;
}
- (void)didMoveToSuperview{
    [super didMoveToSuperview];
}
- (CGFloat)defaultPopW{
    return [self minPopW] * 2;
}
- (CGFloat)minPopW{
    return 100;
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
}

#pragma mark - config

- (void)configUI{
    [super configUI];
    [self addSubview:self.option];
}

#pragma mark - reload

- (void)reloadWithItems:(NSArray <ZHDPListToolItem *> *)items{
    [self.option reloadWithItems:items];
}

#pragma mark - getter

- (ZHDPListOprateOption *)option{
    if (!_option) {
        _option = [[ZHDPListOprateOption alloc] initWithFrame:CGRectZero];
    }
    return _option;
}

@end
