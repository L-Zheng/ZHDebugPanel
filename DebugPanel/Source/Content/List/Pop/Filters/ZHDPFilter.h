//
//  ZHDPFilter.h
//  Pods-Demo
//
//  Created by EM on 2021/9/9.
//

#import "ZHDPComponent.h"
#import "ZHDPDataTask.h"// 数据管理

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPFilter : ZHDPComponent <UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,retain) NSArray *items;

#pragma mark - reload

- (void)reloadListInstant;
- (void)reloadListFrequently;

#pragma mark - click

- (void)selectAllBtnClick;

@end

NS_ASSUME_NONNULL_END
