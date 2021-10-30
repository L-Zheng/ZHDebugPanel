//
//  ZHDPListPop.h
//  ZHJSNative
//
//  Created by EM on 2021/5/29.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPComponent.h"
#import "ZHDPListPopShadow.h"// pop阴影
@class ZHDPList;

@interface ZHDPListPop : ZHDPComponent
@property (nonatomic,weak) ZHDPList *list;

@property (nonatomic,strong) UIButton *bgBtn;
@property (nonatomic,strong) ZHDPListPopShadow *shadowView;

// 子类重写
- (CGFloat)defaultPopW;
- (CGFloat)minPopW;
- (CGFloat)maxPopW;
- (void)updateFrameX:(BOOL)hide;
- (void)updateFrameH;
- (void)show;
- (void)hide;
- (BOOL)allowMaskWhenShow;
- (void)reloadList;
- (void)configUI;

// public func
- (BOOL)isShow;
- (void)reloadListInstant;
- (void)reloadListFrequently;
@end
