//
//  ZHDPDataTask.h
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ZHDPManager;// 调试面板管理
@class ZHDPAppDataItem;// 某个app的数据
@class ZHDPAppItem;

/* 数据结构
 @{
     @"appId": ZHDPAppDataItem
     @"appId": ZHDPAppDataItem
   }

 ZHDPAppDataItem
     ZHDPAppItem *appItem;
     NSMutableArray <ZHDPListSecItem *> *logItems;
     NSMutableArray <ZHDPListSecItem *> *networkItems;
     NSMutableArray <ZHDPListSecItem *> *imItems;
     NSMutableArray <ZHDPListSecItem *> *storageItems;
 */

// list操作栏数据
@interface ZHDPListToolItem : NSObject
@property (nonatomic,copy) NSString *icon;
@property (nonatomic,copy) NSString *desc;
@property (nonatomic,assign,getter=isSelected) BOOL selected;
@property (nonatomic,copy) void (^block) (void);
@end

// 描述list的信息
@interface ZHDPListItem : NSObject
+ (instancetype)itemWithTitle:(NSString *)title;
@property (nonatomic,copy) NSString *title;
@end

// 某条日志的输出类型
typedef NS_ENUM(NSInteger, ZHDPOutputType) {
    ZHDPOutputType_All     = 0,
    ZHDPOutputType_Log     = 1,
    ZHDPOutputType_Info     = 2,
    ZHDPOutputType_Debug     = 3,
    ZHDPOutputType_Warning      = 4,
    ZHDPOutputType_Error      = 5,
};
@interface ZHDPOutputItem : NSObject
+ (NSArray <ZHDPOutputItem *> *)allItems;
+ (NSString *)colorStrByType:(ZHDPOutputType)type;
@property (nonatomic,assign) ZHDPOutputType type;
@property (nonatomic,copy,readonly) NSString *colorStr;
@property (nonatomic,copy,readonly) NSString *desc;
@end

// 某条日志的简要信息
@interface ZHDPFilterItem : NSObject
@property (nonatomic,strong) ZHDPAppItem *appItem;// 属于哪个app
@property (nonatomic,copy) NSString *page;// 属于哪个页面
@property (nonatomic,strong) ZHDPOutputItem *outputItem;// 日志类型
@end

@interface ZHDPFilterListItem : NSObject
@property (nonatomic,strong) ZHDPAppItem *appItem;// 属于哪个app
@property (nonatomic,retain) NSArray <ZHDPFilterItem *> *pageFilterItems;
@end

// list中每一行中每一分段的信息
@interface ZHDPListColItem : NSObject
@property (nonatomic,copy) NSAttributedString *attTitle;
@property (nonatomic,copy) NSString *htmlTitle;
@property (nonatomic,assign) CGFloat percent;
@property (nonatomic,strong) NSValue *rectValue;
@property (nonatomic,strong) NSDictionary *extraInfo;
@end

// list中每一行的信息
@interface ZHDPListRowItem : NSObject
@property (nonatomic,retain) NSArray <ZHDPListColItem *> *colItems;
@property (nonatomic,assign) CGFloat rowH;
@end

// list选中某一组显示的详细信息
@interface ZHDPListDetailItem : NSObject
@property (nonatomic,copy) NSString *title;
@property (nonatomic,retain) NSArray *items;
@property (nonatomic,copy) NSAttributedString *itemsAttStr;
@property (nonatomic,assign,getter=isSelected) BOOL selected;
@property (nonatomic,assign) CGFloat fitWidth;
@end

// list中每一组的信息
@interface ZHDPListSecItem : NSObject
@property (nonatomic,weak) ZHDPAppDataItem *appDataItem;
@property (nonatomic,strong) ZHDPFilterItem *filterItem;

@property (nonatomic,assign) NSTimeInterval enterMemoryTime;
@property (nonatomic,assign,getter=isOpen) BOOL open;
@property (nonatomic,retain) NSArray <ZHDPListColItem *> *colItems;
@property (nonatomic,assign) CGFloat headerH;
@property (nonatomic,retain) NSArray <ZHDPListRowItem *> *rowItems;

@property (nonatomic,retain) NSArray <ZHDPListDetailItem *> *detailItems;

@property (nonatomic,copy) NSString * (^pasteboardBlock) (void);
@end

// 某种类型数据的存储最大容量
@interface ZHDPDataSpaceItem : NSObject
@property (nonatomic,assign) NSInteger count;
@property (nonatomic,assign) CGFloat removePercent;
@property (nonatomic,copy) NSString *storeKey;
@end

// 某个应用的简要信息
@interface ZHDPAppItem : NSObject
@property (nonatomic,copy) NSString *appName;
@property (nonatomic,copy) NSString *appId;
@property (nonatomic,assign,getter=isFundCli) BOOL fundCli;
@end

// list收集量数据
@interface ZHDPListSpaceItem : NSObject
@property (nonatomic,assign,getter=isSelected) BOOL selected;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,weak) ZHDPDataSpaceItem *dataSpaceItem;
@property (nonatomic,assign) NSInteger count;
@property (nonatomic,retain) NSArray *canSelectValues;
@property (nonatomic,copy) void (^block) (NSInteger count);
@end

// 某个应用的数据
@interface ZHDPAppDataItem : NSObject
@property (nonatomic,strong) ZHDPAppItem *appItem;

@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *logItems;
@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *networkItems;
@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *storageItems;
@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *leaksItems;
@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *crashItems;
@property (nonatomic,retain) NSMutableArray <ZHDPListSecItem *> *memoryWarningItems;

@end


// 数据管理
@interface ZHDPDataTask : NSObject

@property (nonatomic,weak) ZHDPManager *dpManager;
@property (nonatomic,strong) NSMutableDictionary *appDataMap;

- (NSArray *)spaceItems;
@property (nonatomic,strong) ZHDPDataSpaceItem *logSpaceItem;
@property (nonatomic,strong) ZHDPDataSpaceItem *networkSpaceItem;
@property (nonatomic,strong) ZHDPDataSpaceItem *storageSpaceItem;
@property (nonatomic,strong) ZHDPDataSpaceItem *leaksSpaceItem;
@property (nonatomic,strong) ZHDPDataSpaceItem *crashSpaceItem;
@property (nonatomic,strong) ZHDPDataSpaceItem *memoryWarningSpaceItem;

// 查找所有应用的数据
- (NSArray <ZHDPAppDataItem *> *)fetchAllAppDataItems;

// 查找某个应用的数据
- (ZHDPAppDataItem *)fetchAppDataItem:(ZHDPAppItem *)appItem;

- (void)cleanAllAppDataItems;
// 清理并添加数据
- (void)cleanAllItems:(NSMutableArray *)items;
- (void)addAndCleanItems:(NSMutableArray *)items item:(ZHDPListSecItem *)item spaceItem:(ZHDPDataSpaceItem *)spaceItem;
@end


