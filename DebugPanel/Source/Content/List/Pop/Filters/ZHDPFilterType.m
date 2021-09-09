//
//  ZHDPFilterType.m
//  Pods-Demo
//
//  Created by EM on 2021/9/9.
//

#import "ZHDPFilterType.h"
#import "ZHDPManager.h"

@implementation ZHDPFilterType

#pragma mark - data

- (void)reloadItems{
    // 修改了self.items要立即刷新
    self.items = [ZHDPOutputItem allItems].copy;
    [self reloadListInstant];
}

#pragma mark - select

- (void)selectIdx:(NSUInteger)idx{
    if (idx >= self.items.count) return;
    [self selectItem:self.items[idx]];
}
- (void)selectItem:(ZHDPOutputItem *)item{
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
    
    ZHDPOutputItem *item = self.items[indexPath.row];
    cell.textLabel.text = item.desc;
    ZHDPOutputType type = item.type;
    
    cell.textLabel.textColor = (type == self.selectItem.type) ? [ZHDPMg() selectColor] : [ZHDPMg() defaultColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self selectIdx:indexPath.row];
    [self reloadListInstant];
}

@end
