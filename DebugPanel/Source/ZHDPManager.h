//
//  ZHDPManager.h
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHDPDataTask.h"// 数据管理
#import "ZHDPNetworkTask.h"// 网络数据截获
#import "ZHDPWindow.h"// 调试面板主窗口
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZHDPManagerStatus) {
    ZHDPManagerStatus_Unknown     = 0,
    ZHDPManagerStatus_Open      = 1,
    ZHDPManagerStatus_Close      = 2
};

@interface ZHDPManager : NSObject

+ (instancetype)shareManager;
@property (nonatomic,assign) ZHDPManagerStatus status;
@property (nonatomic,strong) ZHDPDataTask *dataTask;
@property (nullable,nonatomic,strong) ZHDPWindow *window;

#pragma mark - basic

- (CGFloat)basicW;
- (CGFloat)marginW;

#pragma mark - date

- (NSDateFormatter *)dateByFormat:(NSString *)formatStr;
- (NSDateFormatter *)dateFormat;
- (CGFloat)dateW;

#pragma mark - animate

- (void)doAnimation:(void (^)(void))animation completion:(void (^ __nullable)(BOOL finished))completion;

#pragma mark - open close

- (void)open;
- (void)close;

#pragma mark - network

- (ZHDPNetworkTask *)fetchNetworkTask;

#pragma mark - window

- (UIWindow *)fetchKeyWindow;
- (UIEdgeInsets)fetchKeyWindowSafeAreaInsets;

#pragma mark - float

- (void)updateFloatTitle;

#pragma mark - switch

- (void)switchFloat;
- (void)switchDebugPanel;

#pragma mark - font

- (UIFont *)iconFontWithSize:(CGFloat)fontSize;
- (UIFont *)defaultFont;
- (UIFont *)defaultBoldFont;

#pragma mark - color

- (UIColor *)bgColor;
- (UIColor *)defaultColor;
- (UIColor *)selectColor;
- (UIColor *)defaultLineColor;
- (CGFloat)defaultLineW;
- (CGFloat)defaultCornerRadius;

- (UIColor *)zhdp_colorFromHexString:(NSString *)hexString;

#pragma mark - toast

- (void)showToast:(NSString *)title
       outputType:(ZHDPOutputType)outputType
  animateDuration:(NSTimeInterval)animateDuration
     stayDuration:(NSTimeInterval)stayDuration
       clickBlock:(void (^__nullable) (void))clickBlock
     showComplete:(void (^__nullable) (void))showComplete
     hideComplete:(void (^__nullable) (void))hideComplete;

#pragma mark - data

- (void)convertToString:(id)title block:(void (^) (NSString *conciseStr, NSString *detailStr))block;
- (NSAttributedString *)createDetailAttStr:(NSArray *)titles descs:(NSArray *)descs;

- (void)copySecItemToPasteboard:(ZHDPListSecItem *)secItem;

- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems:(Class)listClass;
- (void)addSecItemToList:(Class)listClass appItem:(ZHDPAppItem *)appItem secItem:(ZHDPListSecItem *)secItem;
- (void)removeSecItemsList:(Class)listClass secItems:(NSArray <ZHDPListSecItem *> *)secItems instant:(BOOL)instant;
//- (void)clearSecItemsList:(Class)listClass appItem:(ZHDPAppItem *)appItem;

@end

@interface ZHDPManager (ZHPlatformTest)

#pragma mark - monitor

- (void)startMonitorMpLog;
- (void)stopMonitorMpLog;
    
#pragma mark - data
    
- (void)zh_test_addLog;
- (void)zh_test_addNetwork:(NSDate *)startDate
                       url:(NSURL *)url
                    method:(NSString *)method
                   headers:(NSDictionary *)headers
                  httpBody:(NSData *)httpBody
            httpBodyStream:(NSData *)httpBodyStream
                  response:(NSURLResponse *)response
              responseData:(NSData *)responseData;

- (void)zh_test_reloadStorage;
- (void)zh_test_deleteStorageStore:(NSArray <ZHDPListSecItem *> *)secItems;
- (void)zh_test_deleteStorageStoreByData:(NSArray *)secItemsData;

- (void)zh_test_reloadMemory;
- (void)zh_test_deleteMemoryStore:(NSArray <ZHDPListSecItem *> *)secItems;
- (void)zh_test_deleteMemoryStoreByData:(NSArray *)secItemsData;

- (void)zh_test_addException:(NSString *)title stack:(NSString *)stack;

@end

__attribute__((unused)) static ZHDPManager * ZHDPMg() {
    return [ZHDPManager shareManager];
}

NS_ASSUME_NONNULL_END

