//
//  ZHDPFilterPage.m
//  Pods-Demo
//
//  Created by EM on 2021/9/9.
//

#import "ZHDPFilterPage.h"
#import "ZHDPManager.h"

@interface ZHDPFilterPage ()
//@property (nonatomic,strong) ZHDPFilterListItem *listItem;
@end

@implementation ZHDPFilterPage

#pragma mark - data

- (void)reloadItem:(ZHDPFilterListItem *)item{
//    self.listItem = item;
    // 修改了self.items要立即刷新
    self.items = item.pageFilterItems.copy;
    [self reloadListInstant];
}

#pragma mark - select

- (void)selectIdx:(NSUInteger)idx{
    if (idx >= self.items.count) return;
    [self selectItem:self.items[idx]];
}
- (void)selectItem:(ZHDPFilterItem *)item{
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
    
    ZHDPFilterItem *filterItem = self.items[indexPath.row];
    cell.textLabel.text = filterItem.page;
    
    NSString *page = self.selectItem.page;
    NSString *appId = self.selectItem.appItem.appId;
    cell.textLabel.textColor = ([appId isEqualToString:filterItem.appItem.appId] && [page isEqualToString:filterItem.page]) ? [ZHDPMg() selectColor] : [ZHDPMg() defaultColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self selectIdx:indexPath.row];
    [self reloadListInstant];
}

@end
