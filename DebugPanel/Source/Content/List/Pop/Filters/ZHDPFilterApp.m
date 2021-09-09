//
//  ZHDPFilterApp.m
//  Pods-Demo
//
//  Created by EM on 2021/9/9.
//

#import "ZHDPFilterApp.h"
#import "ZHDPManager.h"

@implementation ZHDPFilterApp

#pragma mark - data

- (void)reloadItems:(NSArray <ZHDPFilterListItem *> *)items{
    // 修改了self.items要立即刷新
    self.items = items.copy;
    [self reloadListInstant];
    
//    [self selectIdx:0];
}

#pragma mark - select

- (void)selectIdx:(NSUInteger)idx{
    if (idx >= self.items.count) return;
    [self selectItem:self.items[idx]];
}
- (void)selectItem:(ZHDPFilterListItem *)item{
    self.selectItem = item;
    if (self.selectBlock) self.selectBlock(self.selectItem);
}

#pragma mark - click

- (void)selectAllBtnClick{
    [self selectItem:nil];
    [self reloadListInstant];
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    ZHDPFilterListItem *item = self.items[indexPath.row];
    ZHDPAppItem *appItem = item.appItem;
    cell.textLabel.text = appItem.appName;
    
    NSString *appId = self.selectItem.appItem.appId;
    cell.textLabel.textColor = [appId isEqualToString:appItem.appId] ? [ZHDPMg() selectColor] : [ZHDPMg() defaultColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self selectIdx:indexPath.row];
    [self reloadListInstant];
}


@end
