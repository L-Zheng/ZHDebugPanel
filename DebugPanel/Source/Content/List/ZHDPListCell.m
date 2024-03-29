//
//  ZHDPListCell.m
//  ZHJSNative
//
//  Created by EM on 2021/5/26.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPListCell.h"

@interface ZHDPListCell ()
@property (nonatomic,strong) ZHDPListRowItem *item;
@property (nonatomic,strong) ZHDPListRow *rowContent;
@end

@implementation ZHDPListCell

+ (instancetype)cellWithTableView:(UITableView *)tableView{
    NSString *cellID = NSStringFromClass(self);
    ZHDPListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[ZHDPListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // >=xcode13以上编译
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_15_0
        /** 适配iOS15 xcode13
         原来是SectionHeader为透明显示，占其位而不遮挡其下面的任何内容，
         升级后SectionHeader为毛玻璃效果，并且在滚动吸顶和滚出屏幕的过程时会发生颜色渐变
         */
        if (@available(iOS 14.0, *)) {
           self.backgroundConfiguration = [UIBackgroundConfiguration clearConfiguration];
        }
#endif
        
        self.clipsToBounds = YES;
        //        ⚠️[TableView] Changing the background color of UITableViewHeaderFooterView is not supported. Use the background view configuration instead.
        //        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView = [UIView new];
        //        self.selectedBackgroundView = [UIView new];
        
        [self.contentView addSubview:self.rowContent];
        
        [self addGesture];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.rowContent.frame = self.contentView.bounds;
}

- (void)addGesture{
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGes:)];
    [self.contentView addGestureRecognizer:gesture];
    
    UILongPressGestureRecognizer *longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGes:)];
    [self.contentView addGestureRecognizer:longPressGes];
}
- (void)tapGes:(UITapGestureRecognizer *)ges{
    if (self.tapGesBlock) {
        self.tapGesBlock();
    }
}
- (void)longPressGes:(UILongPressGestureRecognizer *)ges{
    if (ges.state == UIGestureRecognizerStateBegan) {
        if (self.longPressGesBlock) {
            self.longPressGesBlock();
        }
    }
}

- (void)configItem:(ZHDPListRowItem *)item{
    self.item = item;
    
    [self.rowContent configItem:item.colItems];
}

- (ZHDPListRow *)rowContent{
    if (!_rowContent) {
        _rowContent = [[ZHDPListRow alloc] initWithFrame:CGRectZero];
    }
    return _rowContent;
}

@end
