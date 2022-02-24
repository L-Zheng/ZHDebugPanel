//
//  ZHDPManager.m
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPManager.h"
#import <CoreText/CoreText.h>
#import "ZHDPOption.h" // 操作栏
#import "ZHDPContent.h"// 内容列表容器
#import "ZHDPListLog.h"// log列表
#import "ZHDPListNetwork.h"// network列表
#import "ZHDPListStorage.h"// storage列表
#import "ZHDPListLeaks.h"// leaks列表
#import "ZHDPListCrash.h"// crash列表
#import "ZHDPListMemoryWarning.h"// 内存警告列表
#import "ZHDPToast.h"//弹窗
#import "UIViewController+ZHDPLeak.h"// 内存泄露监听

NSString * const ZHDPToastFundCliUnavailable = @"本地调试服务未连接\n%@不可用";

// crash捕获
static NSUncaughtExceptionHandler *zhdp_ori_UncaughtExceptionHandler;
void ZHDPUncaughtExceptionHandler(NSException *exception){
    if (zhdp_ori_UncaughtExceptionHandler) {
        zhdp_ori_UncaughtExceptionHandler(exception);
    }
    [ZHDPMg() crash_save:exception];
}

@interface ZHDPManager (){
    CFURLRef _originFontUrl;//注册字体Url
    CTFontDescriptorRef _descriptor;//注册字体Descriptor
}
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,strong) NSDateFormatter *dateFormat;
@property (nonatomic,assign) BOOL debugPanelH5Disable;
@property (nonatomic,strong) ZHDPNetworkTask *networkTask;
@property (nonatomic,strong) NSLock *lock;

@property (nonatomic,retain) NSMutableArray *leak_ctrls;
@end

@implementation ZHDPManager

#pragma mark - crash

- (void)crash_capture{
    zhdp_ori_UncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&ZHDPUncaughtExceptionHandler);
}
- (void)crash_save:(NSException *)exception{
    if (ZHDPMg().status != ZHDPManagerStatus_Open ||
        !exception || ![exception isKindOfClass:[NSException class]]) {
        return;
    }
    
    // 时间
    NSDate *cDate = [NSDate date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateStyle:NSDateFormatterMediumStyle];
    [fmt setTimeStyle:NSDateFormatterShortStyle];
    [fmt setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString *dateStr = [fmt stringFromDate:cDate];
    
    // crash发生时 不要异步切线程 可能还没切成功 app就退出了
    NSString *crashStr = [self parseNativeObjToString:@{
        @"time": dateStr?:@"",
        @"name": exception.name?:@"",
        @"reason": exception.reason?:@"",
        @"callStackSymbols": exception.callStackSymbols?:@[],
        @"userInfo": exception.userInfo?:@{},
        @"app": @{
            @"version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]?:@"",
            @"buildVersion": ([[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey])?:@""
        }
    }];
    if (!crashStr || ![crashStr isKindOfClass:NSString.class] || crashStr.length == 0) {
        return;
    }
    
    // 创建文件
    [fmt setDateFormat:@"yyyy-MM-dd-HH-mm-ss-SSS"];
    NSString *fileName = [fmt stringFromDate:cDate];
    NSString *folder = [self crash_createDir_unreport];
    NSString *file = [folder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", fileName]];
    [crashStr writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    return;
    // 弹窗提示
    __block BOOL isKeepRun = YES;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"发生崩溃" message:crashStr preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"复制并退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        isKeepRun = NO;
    }];
    [alert addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    
    // 保持程序运行
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    while (isKeepRun) {
        for (NSString *mode in (__bridge NSArray *)allModes) {
            CFRunLoopRunInMode((CFStringRef)mode, 0.0001, false);
        }
    }
    CFRelease(runLoop);
}
- (NSArray *)crash_fetchLastFiles{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return @[];
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *folder = [self crash_createDir_unreport];
    NSArray *fileNames = [fm contentsOfDirectoryAtPath:folder error:nil];
    
    NSMutableArray *res = [NSMutableArray array];
    for (NSString *fileName in fileNames) {
        if (!fileName || ![fileName isKindOfClass:NSString.class] || fileName.length == 0 ||
            fileName.pathExtension.length == 0) {
            continue;
        }
        [res addObject:[folder stringByAppendingPathComponent:fileName]];
    }
    return res.copy;
}
- (NSArray *)crash_read:(NSArray *)files{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return @[];
    }
    
    if (!files || ![files isKindOfClass:NSArray.class] || files.count == 0) {
        return @[];
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray *res = [NSMutableArray array];
    for (NSString *file in files) {
        if (!file || ![file isKindOfClass:NSString.class] || file.length == 0) {
            continue;
        }
        
        BOOL isDirectory = YES;
        if (![fm fileExistsAtPath:file isDirectory:&isDirectory] || isDirectory) {
            continue;
        }
        NSData *data = [NSData dataWithContentsOfFile:file];
        if (!data) {
            continue;
        }
        id json = nil;
        @try {
            NSError *jsonError = nil;
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError) json = nil;
        } @catch (NSException *exception) {
        } @finally {
        }
        if (!json) {
            continue;
        }
        [res addObject:json];
    }
    return res.copy;
}
- (void)crash_move:(NSArray *)files{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return;
    }
    
    if (!files || ![files isKindOfClass:NSArray.class] || files.count == 0) {
        return;
    }
    NSString *folder = [self crash_createDir_report];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *file in files) {
        if (!file || ![file isKindOfClass:NSString.class] || file.length == 0 ||
            !file.lastPathComponent || file.lastPathComponent.length == 0) {
            continue;
        }
        
        BOOL isDirectory = YES;
        if (![fm fileExistsAtPath:file isDirectory:&isDirectory] || isDirectory) {
            continue;
        }
        
        NSString *targetFile = [folder stringByAppendingPathComponent:file.lastPathComponent];
        [fm removeItemAtPath:targetFile error:nil];
        [fm moveItemAtPath:file toPath:targetFile error:nil];
    }
}
- (NSString *)crash_createDir_report{
    return [self crash_createDir:@"Report"];
}
- (NSString *)crash_createDir_unreport{
    return [self crash_createDir:@"UnReport"];
}
- (NSString *)crash_createDir:(NSString *)dirName{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *folder = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"ZHDPAppCrash"] stringByAppendingPathComponent:dirName];
    BOOL isDirectory = NO;
    if (![fm fileExistsAtPath:folder isDirectory:&isDirectory] || !isDirectory) {
        [fm removeItemAtPath:folder error:nil];
        [fm createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return folder;
}

#pragma mark - MemoryWarning

- (void)addNoti_memoryWarning{
    [self removeNoti_memoryWarning];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}
- (void)removeNoti_memoryWarning{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}
- (void)appReceiveMemoryWarning:(NSNotification *)noti{
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    if (noti.object) {
        [res setValue:[noti.object description]?:@"" forKey:@"object"];
    }
    if (noti.userInfo.allKeys.count > 0) {
        [res setValue:noti.userInfo forKey:@"userInfo"];
    }
    [self zh_test_addMemoryWarning:nil params:res.copy];
}

#pragma mark - basic

- (CGFloat)basicW{
    return UIScreen.mainScreen.bounds.size.width;
}
- (CGFloat)marginW{
    return 5;
}

#pragma mark - date

- (NSDateFormatter *)dateByFormat:(NSString *)formatStr{
//    @"yyyy-MM-dd HH:mm:ss.SSS"
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateStyle:NSDateFormatterMediumStyle];
    [format setTimeStyle:NSDateFormatterShortStyle];
    [format setDateFormat:formatStr];
    return format;
}
- (NSDateFormatter *)dateFormat{
    if (!_dateFormat) {
        _dateFormat = [self dateByFormat:@"HH:mm:ss.SSS"];
    }
    return _dateFormat;
}
- (CGFloat)dateW{
    NSString *str = [self dateFormat].dateFormat;
    str = @"99:99:99.999";
    CGFloat basicW = [self basicW];
    return [str boundingRectWithSize:CGSizeMake(basicW, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [self defaultFont]} context:nil].size.width + 2 * [self marginW];
}

#pragma mark - animate

- (void)doAnimation:(void (^)(void))animation completion:(void (^ __nullable)(BOOL finished))completion{
//    BOOL isHaveWindow = (_window ? YES : NO);
//    if (isHaveWindow) {
//        [self.window enableDebugPanel:NO];
//    }
//    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:0.20 animations:animation completion:^(BOOL finished) {
        if (completion) completion(finished);
//        if (isHaveWindow) {
//            [weakSelf.window enableDebugPanel:YES];
//        }
    }];
}

#pragma mark - open close

- (void)open{
    dispatch_async(dispatch_get_main_queue(), ^{
    if (self.status == ZHDPManagerStatus_Open) {
        return;
    }
    self.status = ZHDPManagerStatus_Open;
    [self startMonitorMpLog];
    [[self createNetworkTask] interceptNetwork];
    [self addNoti_memoryWarning];
    
    if ([self fetchKeyWindow]) {
        [self openInternal];
        return;
    }
    
    [self addTimer:0.5];
    });
}
- (void)openInternal{
    dispatch_async(dispatch_get_main_queue(), ^{
    if (self.status != ZHDPManagerStatus_Open) {
        return;
    }
    [self.window showFloat:[self fetchFloatTitle]];
    [self.window hideDebugPanel:nil];
    [self zh_test_addCrash];
    });
}
- (void)close{
    __weak __typeof__(_window) _weakWindow = _window;
    dispatch_async(dispatch_get_main_queue(), ^{
    if (self.status != ZHDPManagerStatus_Open) {
        return;
    }
    self.status = ZHDPManagerStatus_Close;
    [self removeTimer];
    [self stopMonitorMpLog];
    [[self fetchNetworkTask] cancelNetwork];
    [self removeNoti_memoryWarning];
    
    if (!_weakWindow) return;
    self.window.hidden = YES;
    self.window = nil;
        
    [self.dataTask cleanAllAppDataItems];
    self.dataTask = nil;
    });
}

#pragma mark - network

- (ZHDPNetworkTask *)fetchNetworkTask{
    [self.lock lock];
    ZHDPNetworkTask *res = self.networkTask;
    [self.lock unlock];
    return res;
}
- (ZHDPNetworkTask *)createNetworkTask{
    [self.lock lock];
    if (!self.networkTask) {
        self.networkTask = [[ZHDPNetworkTask alloc] init];
    }
    ZHDPNetworkTask *res = self.networkTask;
    [self.lock unlock];
    return res;
}

#pragma mark - window

- (UIWindow *)fetchKeyWindow{
    // window必须成为keyWindow  才可创建自定义的window  否则崩溃
    UIWindow *keyWindow = [self topNormalWindow];
    return keyWindow.isKeyWindow ? keyWindow : nil;
}
- (UIEdgeInsets)fetchKeyWindowSafeAreaInsets{
    // 只是获取window的safeAreaInsets  不需要window成为keyWindow
    UIWindow *keyWindow = [self topNormalWindow];
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = [keyWindow safeAreaInsets];
    }
    return safeAreaInsets;
}
- (UIWindow *)topNormalWindow{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow || keyWindow.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *window in windows) {
            if (window.windowLevel == UIWindowLevelNormal){
                keyWindow = window;
                break;
            }
        }
    }
    return keyWindow;
}
- (UIViewController *)topController{
    return [self topController_recursion:[self topNormalWindow].rootViewController];
}
- (UIViewController *)topController_recursion:(UIViewController *)startCtrl{
    while (startCtrl.presentedViewController) {
        startCtrl = startCtrl.presentedViewController;
    }
    
    if ([startCtrl isKindOfClass:[UITabBarController class]]) {
        return [self topController_recursion:((UITabBarController *)startCtrl).selectedViewController];
    } else if ([startCtrl isKindOfClass:[UINavigationController class]]) {
        return [self topController_recursion:((UINavigationController *)startCtrl).visibleViewController];
    } else {
        return startCtrl;
    }
}

#pragma mark - float

- (NSString *)fetchFloatTitle{
    return @"调试台";
}
- (void)updateFloatTitle{
    if (!_window) return;
    [self.window.floatView updateTitle:[self fetchFloatTitle]];
}

#pragma mark - switch

- (void)switchFloat{
    if (!_window) return;
    [self.window showFloat:[self fetchFloatTitle]];
    [self.window hideDebugPanel:nil];
}
- (void)switchDebugPanel{
    if (!_window) return;
    [self.window hideFloat];
    __weak __typeof__(self) weakSelf = self;
    [self.window showDebugPanel:^{
        void (^errorBlock) (void) = weakSelf.window.floatView.clickErrorBlock;
        if (errorBlock) errorBlock();
        [weakSelf.window.floatView stopAnimation];
    }];
    
    if (0) {
        [self showToast:@"点击以\n同步到PC调试" outputType:NSNotFound animateDuration:0.25 stayDuration:3.0 clickBlock:^{
            [ZHDPMg() switchFloat];
        } showComplete:nil hideComplete:nil];
        self.debugPanelH5Disable = YES;
    }
}

#pragma mark - timer

- (void)timeResponse{
    if ([self fetchKeyWindow]) {
        [self removeTimer];
        [self openInternal];
    }
}

- (void)addTimer:(NSTimeInterval)space{
    if (self.timer != nil) return;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:space target:self selector:@selector(timeResponse) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.timer = timer;
}

- (void)removeTimer{
    if (self.timer == nil) return;
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - getter

- (ZHDPDataTask *)dataTask{
    if (!_dataTask) {
        _dataTask = [[ZHDPDataTask alloc] init];
        _dataTask.dpManager = self;
    }
    return _dataTask;
}
- (ZHDPWindow *)window{
    if (!_window) {
        _window = [ZHDPWindow window];
    }
    return _window;
}

#pragma mark - font

- (UIFont *)iconFontWithSize:(CGFloat)fontSize{
    NSString *fontSrc = [[NSBundle mainBundle] pathForResource:@"iconfont" ofType:@"ttf"];
    fontSize = (fontSize > 0 ? fontSize : 17);
    if (fontSrc.length == 0) {
        return [UIFont systemFontOfSize:fontSize];
    }
    NSURL *originFontURL = (__bridge NSURL *)_originFontUrl;
    BOOL isRegistered = (_originFontUrl && _descriptor);
    
    //已经注册同样的字体文件
    if (isRegistered && [originFontURL.path isEqualToString:fontSrc]) {
        return [UIFont fontWithDescriptor:(__bridge UIFontDescriptor *)_descriptor size:fontSize];
    }
    
    //取消注册先前的文件
    if (isRegistered) {
        CTFontManagerUnregisterFontsForURL(_originFontUrl, kCTFontManagerScopeNone, NULL);
        _originFontUrl = nil;
        _descriptor = nil;
    }
    
    //注册新字体文件
    CFURLRef newFontURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)fontSrc, kCFURLPOSIXPathStyle, false);
    CTFontManagerRegisterFontsForURL(newFontURL, kCTFontManagerScopeNone, NULL);
    _originFontUrl = newFontURL;
    CFArrayRef descriptors = CTFontManagerCreateFontDescriptorsFromURL(newFontURL);
    NSInteger count = CFArrayGetCount(descriptors);
    _descriptor = (count >= 1 ? CFArrayGetValueAtIndex(descriptors, 0) : nil);
    if (_originFontUrl && _descriptor) {
        return [UIFont fontWithDescriptor:(__bridge UIFontDescriptor *)_descriptor size:fontSize];
    }else{
        return [UIFont systemFontOfSize:fontSize];
    }
}
- (UIFont *)defaultFont{
    return [UIFont systemFontOfSize:15];
}
- (UIFont *)defaultBoldFont{
    return [UIFont boldSystemFontOfSize:15];
}

#pragma mark - color

- (UIColor *)bgColor{
    return [UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0];
}
- (UIColor *)defaultColor{
    return [UIColor blackColor];
}
- (UIColor *)selectColor{
    return [UIColor colorWithRed:12.0/255.0 green:200.0/255.0 blue:46.0/255.0 alpha:1];
}
- (UIColor *)defaultLineColor{
    return [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1];
    return [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1];
}
- (CGFloat)defaultLineW{
    return 1.0 / UIScreen.mainScreen.scale;
}
- (CGFloat)defaultCornerRadius{
    return 10.0;
}

- (UIColor *)fetchOutputColor:(ZHDPOutputType)type{
    NSString *str = [ZHDPOutputItem colorStrByType:type];
    if (!str || ![str isKindOfClass:NSString.class] || str.length == 0) {
        str = [ZHDPOutputItem colorStrByType:ZHDPOutputType_Log];
    }
    return [self zhdp_str2Color:str];
}
- (UIColor *)zhdp_str2Color:(NSString *)str {
    NSString *colorString = [[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    if ([colorString hasPrefix:@"0x"] || [colorString hasPrefix:@"#"]) {
        return [self zhdp_colorFromHexString:colorString];
    }
    return nil;
}
- (UIColor *)zhdp_colorFromHexString:(NSString *)hexString{
    unsigned rgbValue = 0;
    hexString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&rgbValue];
    
    // 包含透明度
    if (hexString.length == 8) {
        CGFloat r = ((rgbValue & 0xFF000000) >> 24);
        CGFloat g = ((rgbValue & 0xFF0000) >> 16);
        CGFloat b = ((rgbValue & 0xFF00) >> 8);
        CGFloat a = ((rgbValue & 0xFF)) * 1.0 / 255.0;
        return [UIColor colorWithRed:(r * 1.0)/255.0f green:(g * 1.0)/255.0f blue:(b * 1.0)/255.0f alpha:a];
    }
    
    return [UIColor colorWithRed:(((rgbValue & 0xFF0000) >> 16) * 1.0)/255.0f green:(((rgbValue & 0xFF00) >> 8) * 1.0)/255.0f blue:((rgbValue & 0xFF) * 1.0)/255.0f alpha:1.0];
}

#pragma mark - toast

- (void)showToast:(NSString *)title
       outputType:(ZHDPOutputType)outputType
  animateDuration:(NSTimeInterval)animateDuration
     stayDuration:(NSTimeInterval)stayDuration
       clickBlock:(void (^__nullable) (void))clickBlock
     showComplete:(void (^__nullable) (void))showComplete
     hideComplete:(void (^__nullable) (void))hideComplete{
    ZHDPToast *toast = [[ZHDPToast alloc] initWithFrame:CGRectZero];
    toast.title = title;
    toast.outputType = outputType;
    toast.animateDuration = animateDuration;
    toast.stayDuration = stayDuration;
    toast.clickBlock = clickBlock;
    toast.showComplete = showComplete;
    toast.hideComplete = hideComplete;
    
    toast.debugPanel = self.window.debugPanel;
    [toast show];
}

#pragma mark - parse

- (NSString *)parseNativeObjToString:(id)obj{
    if (!obj) return nil;
    if ([obj isKindOfClass:NSString.class]) {
        return obj;
    }else if ([obj isKindOfClass:NSArray.class] ||
        [obj isKindOfClass:NSDictionary.class]) {
        NSString *jsonStr = nil;
        @try {
            NSError *jsonError = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&jsonError];
            jsonStr = ((data && !jsonError) ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil);
        } @catch (NSException *exception) {
        } @finally {
        }
        if (jsonStr) return jsonStr;
        return [obj isKindOfClass:NSArray.class] ? @"[object Array]" : @"[object Object]";
    }else if ([obj isKindOfClass:NSClassFromString(@"__NSCFBoolean")]) {
        return ([(NSNumber *)obj boolValue] ? @"true" : @"false");
    }else if ([obj isKindOfClass:NSData.class]) {
        return [self parseNativeObjToString:[self parseDataToNativeObj:obj]];
    }else if ([obj isKindOfClass:NSNull.class]) {
        return @"[object Null]";
    }
    return [obj description];
}
- (id)parseDataToNativeObj:(NSData *)data{
    if (!data || ![data isKindOfClass:NSData.class]) {
        return nil;
    }
    id res = nil;
    // 尝试json解析
    @try {
        NSError *jsonError = nil;
        res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:&jsonError];
        if (jsonError) res = nil;
    } @catch (NSException *exception) {
    } @finally {
    }
    if (res) return res;
    
    // 尝试string解析
    @try {
        res = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) {
    } @finally {
    }
    
    if (res && [res isKindOfClass:NSString.class] && ((NSString *)res).length > 0) {
        return res;
    }
    
    // string解析失败
    return nil;
}
- (id)parseRequestBodyDataToNativeObj:(NSData *)data{
    id res = [self parseDataToNativeObj:data];
    if (!res) {
        return nil;
    }
    if ([NSJSONSerialization isValidJSONObject:res]) {
        return res;
    }
    if (!res || ![res isKindOfClass:NSString.class] || ((NSString *)res).length == 0) {
        return nil;
    }
    
    // 转json
    NSURLComponents *comp = [[NSURLComponents alloc] init];
    comp.query = res;
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in comp.queryItems) {
        if (item.name.length && item.value.length) {
            [resMap setObject:item.value forKey:item.name];
        }
    }
    if (resMap.allKeys.count > 0) {
        return resMap.copy;
    }
    
    // 转json失败
    return res;
}
- (NSArray *)parseJsData:(JSContext *)jsCtx params:(NSArray *)params forceJsParse:(BOOL)forceJsParse{
    if (!jsCtx || ![jsCtx isKindOfClass:JSContext.class] ||
        !params || ![params isKindOfClass:NSArray.class] || params.count == 0) {
        return nil;
    }
    
    NSMutableArray *jsParseParams = forceJsParse ? [params mutableCopy] : [NSMutableArray array];
    NSMutableArray <NSNumber *> *insertIdxs = [NSMutableArray array];
    NSMutableArray *res = [NSMutableArray array];
    if (!forceJsParse) {
    for (NSUInteger i = 0 ; i < params.count; i++) {
        @autoreleasepool {
            id arg = params[i];
            
            NSString *type = nil;
            id data = nil;
            BOOL error = NO;
            
            if (![arg isKindOfClass:JSValue.class]) {
                if ([arg isKindOfClass:NSDictionary.class]) {
                    type = @"[object Object]";
                }else if ([arg isKindOfClass:NSArray.class]){
                    type = @"[object Array]";
                }else if ([arg isKindOfClass:NSString.class]){
                    type = @"[object String]";
                }else if ([arg isKindOfClass:NSClassFromString(@"__NSCFBoolean")]){
                    type = @"[object Boolean]";
                }else if ([arg isKindOfClass:NSNumber.class]){
                    type = @"[object Number]";
                }else if ([arg isKindOfClass:NSNull.class]){
                    type = @"[object Null]";
                }
                type = type;
                data = arg;
                error = NO;
            }else{
                JSValue *jsValue = (JSValue *)arg;
                if (jsValue.isNull) {
                    type = @"[object Null]";
                    data = [NSNull null];
                    error = NO;
                } else if (jsValue.isUndefined) {
                    type = @"[object Undefined]";
                    data = nil;
                    error = NO;
                } else if (jsValue.isBoolean){
                    type = @"[object Boolean]";
                    data = @([jsValue toBool]);
                    error = NO;
                } else if (jsValue.isString){
                    type = @"[object String]";
                    data = [jsValue toString];
                    error = NO;
                } else if (jsValue.isNumber){
                    type = @"[object Number]";
                    data = [jsValue toNumber];
                    error = NO;
                } else {
                    [insertIdxs addObject:@(i)];
                    [jsParseParams addObject:arg];
                    continue;
                }
            }
            [res addObject:@{
                @"type": type?:@"未知数据类型",
                @"data": data ? data : @"[object Undefined]",
                @"error": @(error)
            }];
        }
    }
    }
    
    if (insertIdxs.count == 0) {
        return res.copy;
    }
    
    NSString *parseFuncName = @"fw_parse_jsdata_to_native";
    JSValue *parseFunc = [jsCtx objectForKeyedSubscript:parseFuncName];
    if (parseFunc.isUndefined || !parseFunc.isObject) {
        [jsCtx evaluateScript:[NSString stringWithFormat:
@" \
var %@ = function (fw_args) { \
   var fw_parse_data_fail = '只接收基础数据类型, 当前数据中包含js特有对象, 原生JSON.stringify()失败.'; \
   var fw_parse_args_res = []; \
   fw_args.forEach(function(fw_arg){ \
       var fw_parse_arg_res = null; \
       var fw_parse_type = Object.prototype.toString.call(fw_arg); \
       try { \
           var fw_parse_data = null; \
           /** 如果fw_arg里面带有[object Function] \
            * JSON.parse(JSON.stringify(fw_arg))  会丢弃该数据 \
            * 如果带有js特有的对象 会触发catch \
            */ \
           if (fw_parse_type == '[object Object]' || fw_parse_type == '[object Array]') { \
               fw_parse_data = JSON.parse(JSON.stringify(fw_arg)); \
           } else if (fw_parse_type == '[object String]' || fw_parse_type == '[object Number]' || fw_parse_type == '[object Null]' || fw_parse_type == '[object Boolean]') { \
               fw_parse_data = fw_arg; \
           } else if (fw_parse_type == '[object Undefined]'){ \
               fw_parse_data = '[object Undefined]'; \
           } else if (fw_parse_type == '[object Error]'){ \
                var fw_error_stack = fw_arg.stack || null; \
                if (Object.prototype.toString.call(fw_error_stack) == '[object String]' && (fw_error_stack.indexOf('\\n') != -1)) { \
                    fw_error_stack = fw_error_stack.split('\\n'); \
                } \
               fw_parse_data = JSON.parse(JSON.stringify({ \
                   message: fw_arg.toString() || null, \
                   stack: fw_error_stack || null, \
                   sourceURL: fw_arg.sourceURL || null, \
                   line: fw_arg.line || 0, \
                   column: fw_arg.column || 0 \
               })); \
           } else { \
               try { \
                   fw_parse_data = fw_arg.toString() || '.toString()解析结果为空'; \
               } catch (error) { \
                   fw_parse_data = '尝试.toString()解析失败'; \
               } \
           } \
           fw_parse_arg_res = { \
               type: fw_parse_type, \
               data: fw_parse_data, \
               error: false \
           }; \
       } catch (error) { \
           fw_parse_arg_res = { \
               type: fw_parse_type, \
               data: fw_parse_data_fail, \
               error: true \
           }; \
       } \
       fw_parse_args_res.push(fw_parse_arg_res); \
   }); \
   return fw_parse_args_res; \
};\
", parseFuncName]];
        parseFunc = [jsCtx objectForKeyedSubscript:parseFuncName];
    }
    NSArray *jsParseRes = [[parseFunc callWithArguments:@[jsParseParams.copy]] toObject];
    
    if (forceJsParse) {
        return jsParseRes;
    }

    if (jsParseRes.count != insertIdxs.count) {
        return res.copy;
    }
    for (NSUInteger i = 0; i < jsParseRes.count; i++) {
        @autoreleasepool {
            NSDictionary *jsParse = jsParseRes[i];
            [res insertObject:jsParse atIndex:insertIdxs[i].unsignedIntegerValue];
        }
    }
    return res.copy;
}
- (BOOL)allowParseToHtml{
    return NO;
}
- (NSString *)parseAttributedStringToHtml:(NSAttributedString *)attStr mixinKey:(NSString *)mixinKey{
    NSString *htmlString = @"";
    if (![self allowParseToHtml]) {
        return htmlString;
    }
    if (!attStr || ![attStr isKindOfClass:NSAttributedString.class]) {
        return htmlString;
    }
    /*
     // DTCoreText的转html消耗性能较高  暂时停用
    DTHTMLWriter *htmlWriter = [[DTHTMLWriter alloc] initWithAttributedString:attStr];
    htmlString = [htmlWriter HTMLString];
    */
    
     // 系统的转html消耗性能较高  暂时停用
       // 并且报警告Incorrect NSStringEncoding value 0x8000100 detected. Assuming NSASCIIStringEncoding. Will stop this compatibility mapping behavior in the near future
    NSDictionary *documentAttributes = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType};
    NSData *htmlData = [attStr dataFromRange:NSMakeRange(0, attStr.length) documentAttributes:documentAttributes error:NULL];
    htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    
    // 处理标签样式为单独作用域  默认生成的style为全局作用域  当有多个htmlStr同时在h5中显示时  会出现style样式冲突
    NSString *randomKey = [NSString stringWithFormat:@"%@-%.0f-%d-%d", mixinKey, [[NSDate date] timeIntervalSince1970] * 1000000, arc4random_uniform(1000), arc4random_uniform(1000)];
    
    NSUInteger limit = 100;
    NSArray *markKeys = @[@[@"p.p", @"class=\"p"], @[@"span.s", @"class=\"s"]];
    for (NSUInteger i = 0; i < limit; i++) {
        for (NSArray *marks in markKeys) {
            @autoreleasepool {
                NSString *key = [NSString stringWithFormat:@"%@%ld", marks[0], i];
                NSString *targetKey = [NSString stringWithFormat:@"%@%ld-%@", marks[0], i, randomKey];
                htmlString = [htmlString stringByReplacingOccurrencesOfString:key withString:targetKey];
                
                key = [NSString stringWithFormat:@"%@%ld\"", marks[1], i];
                targetKey = [NSString stringWithFormat:@"%@%ld-%@\" style=\"font-size:%.2fpx;\"", marks[1], i, randomKey, [self defaultFont].pointSize + 2];
                htmlString = [htmlString stringByReplacingOccurrencesOfString:key withString:targetKey];
            }
        }
    }
    return htmlString;
}

#pragma mark - data

- (ZHDPListColItem *)createColItem:(NSString *)formatData percent:(CGFloat)percent X:(CGFloat)X colorType:(ZHDPOutputType)colorType{

    formatData = formatData?:@"";
    NSMutableAttributedString *tAtt = nil;

    NSUInteger limit = 200;
    if ([formatData isKindOfClass:NSAttributedString.class]) {
        tAtt = [[NSMutableAttributedString alloc] initWithAttributedString:(NSAttributedString *)formatData];
        NSUInteger titleLength = [(NSAttributedString *)formatData string].length;
        if (titleLength >= limit) {
            tAtt = [[NSMutableAttributedString alloc] initWithAttributedString:[tAtt attributedSubstringFromRange:NSMakeRange(0, limit - 1)]];
            [tAtt appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n...点击展开" attributes:@{NSFontAttributeName: [self defaultFont], NSForegroundColorAttributeName: [self selectColor]}]];
        }
    }else{
        tAtt = [[NSMutableAttributedString alloc] init];
        
        NSUInteger titleLength = formatData.length;
        if (titleLength < limit) {
            [tAtt appendAttributedString:[[NSAttributedString alloc] initWithString:formatData attributes:@{NSFontAttributeName: [self defaultFont], NSForegroundColorAttributeName: [self fetchOutputColor:colorType]}]];
        }else{
            formatData = [formatData substringToIndex:limit - 1];
            [tAtt appendAttributedString:[[NSAttributedString alloc] initWithString:formatData attributes:@{NSFontAttributeName: [self defaultFont], NSForegroundColorAttributeName: [self fetchOutputColor:colorType]}]];
            [tAtt appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n...点击展开" attributes:@{NSFontAttributeName: [self defaultFont], NSForegroundColorAttributeName: [self selectColor]}]];
        }
    }
    
    ZHDPListColItem *colItem = [[ZHDPListColItem alloc] init];
    colItem.attTitle = [[NSAttributedString alloc] initWithAttributedString:tAtt];
    colItem.percent = percent;
    CGFloat width = [self basicW] * colItem.percent - 2 * [self marginW];

    CGSize fitSize = [colItem.attTitle boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    colItem.rectValue = [NSValue valueWithCGRect:CGRectMake(X, 0, width + 2 * [self marginW], fitSize.height + 2 * [self marginW])];

    return colItem;
}
- (ZHDPListDetailItem *)createDetailItem:(NSString *)title keys:(NSArray *)keys values:(NSArray *)values{
    NSUInteger minCount = MIN(keys.count, values.count);
    if (minCount == 0) {
        return nil;
    }
    
    NSMutableArray *items = [NSMutableArray array];
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 5;
    
    for (NSUInteger i = 0; i < minCount; i++) {
        @autoreleasepool {
            NSString *key = [self removeEscapeCharacter:keys[i]];
            NSString *value = values[i];
            BOOL isAttStr = [value isKindOfClass:NSAttributedString.class];
            if (!isAttStr) {
                value = [self removeEscapeCharacter:value];
            }
            
            NSAttributedString *keyAtt = [[NSAttributedString alloc] initWithString:key attributes:@{
                NSFontAttributeName: [self defaultBoldFont],
                NSForegroundColorAttributeName: [self selectColor],
                NSParagraphStyleAttributeName: style
            }];
            NSAttributedString *valueAtt = nil;
            if (isAttStr) {
                valueAtt = value.copy;
            }else{
                valueAtt = [[NSAttributedString alloc] initWithString:value attributes:@{
                    NSFontAttributeName: [self defaultFont],
                    NSForegroundColorAttributeName: [self defaultColor],
                    NSParagraphStyleAttributeName: style
                }];
            }
            NSAttributedString *lineAtt = [[NSAttributedString alloc] initWithString:@"\n" attributes:@{
                NSFontAttributeName: [self defaultBoldFont],
                NSForegroundColorAttributeName: [self selectColor],
                NSParagraphStyleAttributeName: style
            }];
            
            [attStr appendAttributedString:keyAtt];
            [attStr appendAttributedString:lineAtt.copy];
            [attStr appendAttributedString:valueAtt];
            if (i < minCount - 1) {
                [attStr appendAttributedString:lineAtt.copy];
            }
            [items addObject:@{
                @"key": key,
                @"value": isAttStr ? valueAtt.string : value
            }];
        }
    }
    
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = [NSString stringWithFormat:@"%@", title];
    item.items = items.copy;
    item.itemsAttStr = attStr.copy;
    return item;
}
- (NSString *)removeEscapeCharacter:(NSString *)str{
    if (!str || ![str isKindOfClass:NSString.class] || str.length == 0) {
        return str;
    }
    return [str stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
}
- (NSString *)removeAppSandBox:(NSString *)str{
    if (!str || ![str isKindOfClass:NSString.class] || str.length == 0) {
        return str;
    }
    str = [self removeEscapeCharacter:str];
    NSString *appBundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *appBundleName = [appBundlePath pathComponents].lastObject;
    NSString *appSandBoxPath = NSHomeDirectory();
    if ([str containsString:appBundlePath]) {
        str = [str stringByReplacingOccurrencesOfString:appBundlePath withString:appBundleName];
    }
    if ([str containsString:appSandBoxPath]) {
        str = [str stringByReplacingOccurrencesOfString:appSandBoxPath withString:@""];
    }
    return str;
}
- (void)copySecItemToPasteboard:(ZHDPListSecItem *)secItem{
    if (secItem.pasteboardBlock) {
        NSString *str = secItem.pasteboardBlock();
        // 去除转义字符
        str = [self removeEscapeCharacter:str];
        [[UIPasteboard generalPasteboard] setString:str];
        [ZHDPMg() showToast:@"已复制，点击分享" outputType:NSNotFound animateDuration:0.25 stayDuration:1.0 clickBlock:^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"weixin://"]];
        } showComplete:nil hideComplete:nil];
    }
}
- (NSString *)createDetailItemsString:(NSArray *)detailItems{
    NSMutableString *str = [NSMutableString string];
    for (NSUInteger i = 0; i < detailItems.count; i++) {
        ZHDPListDetailItem *item = detailItems[i];
        [str appendFormat:@"%@%@:\n%@", (i == 0 ? @"" : @"\n"), item.title, item.itemsAttStr.string];
    }
    return str.copy;
}

- (NSString *)opSecItemsMapKey_items{
    return @"itemsBlock";
}
- (NSString *)opSecItemsMapKey_space{
    return @"spaceBlock";
}
- (NSString *)opSecItemsMapKey_sendSocket{
    return @"sendSocketBlock";
}
- (NSDictionary *)opSecItemsMap{
    NSString *itemsKey = [self opSecItemsMapKey_items];
    NSString *spaceKey = [self opSecItemsMapKey_space];
    NSString *sendSocketKey = [self opSecItemsMapKey_sendSocket];
    __weak __typeof__(self) weakSelf = self;
    return @{
        NSStringFromClass(ZHDPListLog.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.logItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return weakSelf.dataTask.logSpaceItem;
                },
                sendSocketKey: ^NSString *(void){
                    return @"log-list";
                }
        },
        NSStringFromClass(ZHDPListNetwork.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.networkItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return weakSelf.dataTask.networkSpaceItem;
                },
                sendSocketKey: ^NSString *(void){
                    return @"network-list";
                }
        },
        NSStringFromClass(ZHDPListStorage.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.storageItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return weakSelf.dataTask.storageSpaceItem;
                },
                sendSocketKey: ^NSString *(void){
                    return @"storage-list";
                }
        },
        NSStringFromClass(ZHDPListLeaks.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.leaksItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return weakSelf.dataTask.leaksSpaceItem;
                },
                sendSocketKey: ^NSString *(void){
                    return @"leaks-list";
                }
        },
        NSStringFromClass(ZHDPListCrash.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.crashItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return weakSelf.dataTask.crashSpaceItem;
                },
                sendSocketKey: ^NSString *(void){
                    return @"crash-list";
                }
        },
        NSStringFromClass(ZHDPListMemoryWarning.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.memoryWarningItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return weakSelf.dataTask.memoryWarningSpaceItem;
                },
                sendSocketKey: ^NSString *(void){
                    return @"memoryWarning-list";
                }
        }
    };
}

- (NSArray <ZHDPListSecItem *> *)fetchAllAppDataItems:(Class)listClass{
    ZHDPManager *dpMg = ZHDPMg();
    
    NSDictionary *map = [dpMg opSecItemsMap];
    NSMutableArray * (^itemsBlock) (ZHDPAppDataItem *) = [[map objectForKey:NSStringFromClass(listClass)] objectForKey:[dpMg opSecItemsMapKey_items]];
    
    if (!itemsBlock) return nil;
    
    NSMutableArray *res = [NSMutableArray array];
    NSArray <ZHDPAppDataItem *> *appDataItems = [dpMg.dataTask fetchAllAppDataItems];
    for (ZHDPAppDataItem *appDataItem in appDataItems) {
        [res addObjectsFromArray:itemsBlock(appDataItem).copy];
    }
    // 按照进入内存的时间 升序排列
    [res sortUsingComparator:^NSComparisonResult(ZHDPListSecItem *obj1, ZHDPListSecItem  *obj2) {
        if (obj1.enterMemoryTime > obj2.enterMemoryTime) {
            return NSOrderedDescending;
        }else if (obj1.enterMemoryTime < obj2.enterMemoryTime){
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
    return res.copy;
}
// self.window  window一旦创建就会自动显示在屏幕上
// 如果当前列表正在显示，刷新列表
- (void)addSecItemToList:(Class)listClass appItem:(ZHDPAppItem *)appItem secItem:(ZHDPListSecItem *)secItem{
    
    ZHDPManager *dpMg = ZHDPMg();
    
    NSDictionary *map = [self opSecItemsMap];
    NSMutableArray * (^itemsBlock) (ZHDPAppDataItem *) = [[map objectForKey:NSStringFromClass(listClass)] objectForKey:[self opSecItemsMapKey_items]];
    ZHDPDataSpaceItem * (^spaceBlock) (ZHDPAppDataItem *) = [[map objectForKey:NSStringFromClass(listClass)] objectForKey:[self opSecItemsMapKey_space]];
    if (!itemsBlock || !spaceBlock) {
        return;
    }
    
    // 追加到全局数据管理
    ZHDPAppDataItem *appDataItem = [dpMg.dataTask fetchAppDataItem:appItem];
    secItem.appDataItem = appDataItem;
    [dpMg.dataTask addAndCleanItems:itemsBlock(appDataItem) item:secItem spaceItem:spaceBlock(appDataItem)];
    
    // 如果当前列表正在显示，刷新列表
    if (_window) {
        ZHDebugPanel *debugPanel = self.window.debugPanel;
        __weak __typeof__(debugPanel) weakDebugPanel = debugPanel;
        
        ZHDebugPanelStatus status = debugPanel.status;
        BOOL isException = NO;
        BOOL isLeaks = [listClass isEqual:ZHDPListLeaks.class];
        BOOL isCrash = [listClass isEqual:ZHDPListCrash.class];
        BOOL isMemoryWarning = [listClass isEqual:ZHDPListMemoryWarning.class];
        BOOL isReport = (isException || isLeaks || isCrash || isMemoryWarning);
        
        if (status == ZHDebugPanelStatus_Show) {
            ZHDPList *list = debugPanel.content.selectList;
            if ([list isKindOfClass:listClass]) {
                [list addSecItem:secItem spaceItem:spaceBlock(appDataItem)];
            }else{
                if (isReport) {
                    NSString *desc = nil;
                    NSTimeInterval duration = 1.5;
                    ZHDPOutputType reportType = ZHDPOutputType_Error;
                    if (isLeaks) {
                        desc = @"检测到内存泄漏\n点击查看";
                    }else if (isException){
                        desc = [NSString stringWithFormat:@"%@\n检测到异常, 点击查看", appItem.appName];
                    }else if (isCrash){
                        desc = @"检测到崩溃信息\n点击查看";
                        duration = 5.0;
                    }else if (isMemoryWarning){
                        desc = @"检测到内存警告\n点击查看";
                        reportType = ZHDPOutputType_Warning;
                    }
                    // 弹窗提示
                    [self showToast:desc outputType:reportType animateDuration:0.25 stayDuration:duration clickBlock:^{
                        [weakDebugPanel.option selectListClass:listClass];
                    } showComplete:nil hideComplete:nil];
                }
            }
        }else if (status == ZHDebugPanelStatus_Hide || status == ZHDebugPanelStatus_Unknown){
            if (isReport) {
                NSString *desc = nil;
                NSTimeInterval aniCount = 5;
                ZHDPOutputType reportType = ZHDPOutputType_Error;
                if (isLeaks) {
                    desc = @"检测到\n内存泄漏";
                }else if (isException){
                    desc = [NSString stringWithFormat:@"%@\n检测到异常", appItem.appName];
                }else if (isCrash){
                    desc = @"检测到\n崩溃信息";
                    aniCount = 20.0;
                }else if (isMemoryWarning){
                    desc = @"检测到\n内存警告";
                    reportType = ZHDPOutputType_Warning;
                }
                [self.window.floatView showTip:desc animateCount:aniCount outputType:reportType clickBlock:^{
                    [weakDebugPanel.option selectListClass:listClass];
                }];
            }
        }
    }
}
- (void)removeSecItemsList:(Class)listClass secItems:(NSArray <ZHDPListSecItem *> *)secItems instant:(BOOL)instant{
    if (!secItems || ![secItems isKindOfClass:NSArray.class] || secItems.count == 0) {
        return;
    }
    NSDictionary *map = [self opSecItemsMap];
    NSMutableArray * (^itemsBlock) (ZHDPAppDataItem *) = [[map objectForKey:NSStringFromClass(listClass)] objectForKey:[self opSecItemsMapKey_items]];
    if (!itemsBlock) {
        return;
    }
    for (ZHDPListSecItem *secItem in secItems) {
        if (!secItem || ![secItem isKindOfClass:ZHDPListSecItem.class]) {
            continue;
        }
        NSMutableArray *items = itemsBlock(secItem.appDataItem);
        if (!items || ![items isKindOfClass:NSArray.class] || items.count == 0) {
            continue;
        }
        
        // 从全局数据管理中删除
        if ([items containsObject:secItem]) {
            [items removeObject:secItem];
        }
        
        // 如果当前列表正在显示，从列表中删除，刷新列表
        if (_window && self.window.debugPanel.status == ZHDebugPanelStatus_Show) {
            ZHDPList *list = self.window.debugPanel.content.selectList;
            if ([list isKindOfClass:listClass]) {
                [list removeSecItems:@[secItem] instant:instant];
            }
        }
    }
}
/*
- (void)clearSecItemsList:(Class)listClass appItem:(ZHDPAppItem *)appItem{
    NSDictionary *map = [self opSecItemsMap];
    NSMutableArray * (^itemsBlock) (ZHDPAppDataItem *) = [[map objectForKey:NSStringFromClass(listClass)] objectForKey:[self opSecItemsMapKey_items]];
    if (!itemsBlock) {
        return;
    }
    
    ZHDPManager *dpMg = ZHDPMg();
    // 是否清除所有
    BOOL isRemoveAll = (!appItem || ![appItem isKindOfClass:ZHDPAppItem.class]);
    
    // 从全局数据管理中移除数据
    NSArray <ZHDPAppDataItem *> *appDataItems = nil;
    if (isRemoveAll) {
        appDataItems = [dpMg.dataTask fetchAllAppDataItems];
    }else{
        ZHDPAppDataItem *appDataItem = [dpMg.dataTask fetchAppDataItem:appItem];
        appDataItems = (appDataItem ? @[appDataItem] : @[]);
    }
    for (ZHDPAppDataItem *appDataItem in appDataItems) {
        [dpMg.dataTask cleanAllItems:itemsBlock(appDataItem)];
    }
    
    // 如果当前列表正在显示，从列表中删除，刷新列表
    if (_window && self.window.debugPanel.status == ZHDebugPanelStatus_Show) {
        ZHDPList *list = self.window.debugPanel.content.selectList;
        if (1) {
            [list clearSecItems];
        }
    }
}
*/

#pragma mark - socket

- (void)sendSocketClientAllDataToList{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) return;
    if (!_window) return;
    
    ZHDebugPanel *debugPanel = self.window.debugPanel;
    NSArray <ZHDPList *> *lists = [debugPanel.content fetchAllLists];
    for (ZHDPList *list in lists) {
        Class cls = [list class];
        NSArray *items = [ZHDPMg() fetchAllAppDataItems:cls];
        for (ZHDPListSecItem *secItem in items) {
            [self sendSocketClientSecItemToList:cls appItem:secItem.filterItem.appItem secItem:secItem colorType:secItem.filterItem.outputItem.type];
        }
    }
}
- (void)sendSocketClientSecItemToList:(Class)listClass appItem:(ZHDPAppItem *)appItem secItem:(ZHDPListSecItem *)secItem colorType:(ZHDPOutputType)colorType{
    if (!secItem) {
        return;
    }

    NSMutableArray *rowItems = [NSMutableArray array];
    for (ZHDPListRowItem *rowItem in secItem.rowItems) {
        NSMutableArray *colItems = [NSMutableArray array];
        for (NSUInteger i = 0; i < rowItem.colItems.count; i++) {
            ZHDPListColItem *colItem = rowItem.colItems[i];
            [colItems addObject:@{
                @"title": [self removeEscapeCharacter:colItem.attTitle.string?:@""],
//                @"titleHtml": [self parseAttributedStringToHtml:colItem.attTitle mixinKey:[NSString stringWithFormat:@"col-%ld", i]],
                @"percent": @(colItem.percent),
                @"color": [ZHDPOutputItem colorStrByType:colorType]?:@"#000000",
                @"extraInfo": colItem.extraInfo?:@{}
            }];
        }
        [rowItems addObject:@{
//            @"useHtml": @([self allowParseToHtml]),
            @"colItems": colItems.copy
        }];
    }
    NSMutableArray *detailItems = [NSMutableArray array];
    for (NSUInteger i = 0; i < secItem.detailItems.count; i++) {
        ZHDPListDetailItem *detailItem = secItem.detailItems[i];
        [detailItems addObject:@{
            @"title": [self removeEscapeCharacter:detailItem.title?:@""],
            @"items": detailItem.items?:@[],
//            @"useHtml": @([self allowParseToHtml]),
//            @"contentHtml": [self parseAttributedStringToHtml:detailItem.itemsAttStr mixinKey:[NSString stringWithFormat:@"detail-%ld", i]],
            @"selected": @(NO)
        }];
    }
    
    NSString *(^block) (void) = [[[self opSecItemsMap] objectForKey:NSStringFromClass(listClass)] objectForKey:[self opSecItemsMapKey_sendSocket]];
    NSString *listId = block ? block() : @"";
    
    if (!appItem.appId || ![appItem.appId isKindOfClass:NSString.class] || appItem.appId.length == 0) {
        return;
    }
        
    NSDictionary *sendAppItem = @{
        @"appId": ((!appItem.appId || ![appItem.appId isKindOfClass:NSString.class] || appItem.appId.length == 0) ? @"App" : appItem.appId),
        @"appName": (!appItem.appName || ![appItem.appName isKindOfClass:NSString.class] || appItem.appName.length == 0) ? @"App" : appItem.appName
    };

    NSDictionary *res = @{
        @"listId": listId?:@"",
        @"appItem": sendAppItem,
        @"msg": @{
                @"filterItem": @{
                        @"appItem": sendAppItem,
                        @"page": secItem.filterItem.page?:@"",
                        @"outputItem": @{
                                @"type": @(secItem.filterItem.outputItem.type),
                                @"desc": secItem.filterItem.outputItem.desc?:@""
                        }
                },
                @"enterMemoryTime": @(secItem.enterMemoryTime),
                @"open": @(YES),
                @"colItems": @[],
                @"rowItems": rowItems.copy,
                @"detailItems": detailItems.copy
        }
    };
    // 发送到调试端
}

#pragma mark - delete

- (void)execAutoDelete{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) return;
    if (!_window) return;
    __weak __typeof__(self) __self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) return;
        if (!__self.window.debugPanel.content.selectList) return;
        NSArray <ZHDPList *> *lists = [self.window.debugPanel.content fetchAllLists];
        for (ZHDPList *list in lists) {
            [list execAutoDeleteList];
        }
    });
}

#pragma mark - leaks controller

- (void)addLeak_controller_dismiss:(SEL)sel sourceCtrl:(UIViewController *)sourceCtrl{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return;
    }
    if (!sourceCtrl || ![sourceCtrl isKindOfClass:UIViewController.class]) {
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    // 获取待释放的controller
    NSMutableArray *resCtrls = [NSMutableArray array];
    UIViewController *presentedCtrl = sourceCtrl.presentedViewController;
    if (presentedCtrl) {
        UIViewController *lastCtrl = nil;
        while (presentedCtrl) {
            [resCtrls addObjectsFromArray:[self fetchController_child:presentedCtrl]];
            if (!presentedCtrl.presentedViewController) {
                lastCtrl = presentedCtrl;
            }
            presentedCtrl = presentedCtrl.presentedViewController;
        }
        // 加入引用表
        NSDictionary *leak = [self addLeak_controller:sel sourceCtrl:sourceCtrl ctrls:resCtrls];
        if (leak) {
            lastCtrl.zhdp_leak_viewDidDisappear = ^{
                [weakSelf checkLeaked_delay_controller:@[leak]];
            };
        }
        return;
    }
    if (sourceCtrl.presentingViewController) {
        UIViewController *resCtrl = sourceCtrl;
        UIViewController *pCtrl = resCtrl.parentViewController;
        while (pCtrl) {
            resCtrl = pCtrl;
            pCtrl = pCtrl.parentViewController;
        }
        [resCtrls addObjectsFromArray:[self fetchController_child:resCtrl]];
        
        // 加入引用表
        NSDictionary *leak = [self addLeak_controller:sel sourceCtrl:sourceCtrl ctrls:resCtrls];
        if (leak) {
            resCtrl.zhdp_leak_viewDidDisappear = ^{
                [weakSelf checkLeaked_delay_controller:@[leak]];
            };
        }
        return;
    }
}
- (void)addLeak_controller_navi_pop:(SEL)sel sourceCtrl:(UINavigationController *)sourceCtrl popCtrls:(NSArray <UIViewController *> *)popCtrls{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return;
    }
    if (!sourceCtrl || ![sourceCtrl isKindOfClass:UINavigationController.class] ||
        !popCtrls || ![popCtrls isKindOfClass:NSArray.class] || popCtrls.count == 0) {
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    // 获取待释放的controller
    NSMutableArray *resCtrls = [NSMutableArray array];
    for (UIViewController *popCtrl in popCtrls) {
        [resCtrls addObjectsFromArray:[self fetchController_child:popCtrl]];
    }
    // 加入引用表
    NSDictionary *leak = [self addLeak_controller:sel sourceCtrl:sourceCtrl ctrls:resCtrls];
    if (leak) {
        if (sourceCtrl.presentedViewController) {
            [self checkLeaked_delay_controller:@[leak]];
        }else{
            popCtrls.lastObject.zhdp_leak_viewDidDisappear = ^{
                [weakSelf checkLeaked_delay_controller:@[leak]];
            };
        }
    }
}
- (void)addLeak_controller_navi_setCtrls:(SEL)sel sourceCtrl:(UINavigationController *)sourceCtrl oriCtrls:(NSArray *)oriCtrls newCtrls:(NSArray *)newCtrls{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return;
    }
    if (!sourceCtrl || ![sourceCtrl isKindOfClass:UINavigationController.class] ||
        !oriCtrls || ![oriCtrls isKindOfClass:NSArray.class] || oriCtrls.count == 0 ||
        !newCtrls || ![newCtrls isKindOfClass:NSArray.class]) {
        return;
    }
    NSMutableArray *oriCtrls_t = [oriCtrls mutableCopy];
    [oriCtrls_t removeObjectsInArray:newCtrls];
    
    // 获取待释放的controller
    NSMutableArray *resCtrls = [NSMutableArray array];
    for (UIViewController *ctrlT in oriCtrls_t) {
        [resCtrls addObjectsFromArray:[self fetchController_child:ctrlT]];
    }
    // 加入引用表
    NSDictionary *leak = [self addLeak_controller:sel sourceCtrl:sourceCtrl ctrls:resCtrls];
    if (leak) {
        [self checkLeaked_delay_controller:@[leak]];
    }
}
- (NSDictionary *)addLeak_controller:(SEL)sel sourceCtrl:(UIViewController *)sourceCtrl ctrls:(NSArray *)ctrls{
    if (!sourceCtrl || ctrls.count == 0) {
        return nil;
    }
    
    // 时间
    NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
    [dateFmt setDateStyle:NSDateFormatterMediumStyle];
    [dateFmt setTimeStyle:NSDateFormatterShortStyle];
    [dateFmt setDateFormat:@"HH:mm:ss.SSS"];
    /*构造数据
     {
         "time": "10:43:10.367",
         "leaks" : [
           {
             "desc" : "",
             "class" : "",
             "address" : "0x7ff7339af600"
           }
         ],
         "trigger" : {
           "desc" : "",
           "class" : "",
           "address" : "0x7ff732851800",
           "function" : "dismissViewController"
         }
       }
     */
    NSMutableDictionary *resMap = [NSMutableDictionary dictionary];
    
    [resMap setObject:[dateFmt stringFromDate:[NSDate date]] forKey:@"time"];
    
    NSPointerArray *sourcePointer = [NSPointerArray weakObjectsPointerArray];
    [sourcePointer addPointer:(__bridge void * _Nullable)(sourceCtrl)];
    [resMap setObject:@{
        @"desc": [sourceCtrl description]?:(sourceCtrl.title?:@""),
        @"class": NSStringFromClass([sourceCtrl class])?:@"",
        @"address": [NSString stringWithFormat:@"%p", sourceCtrl],
        @"function": NSStringFromSelector(sel)?:@"",
        @"point": sourcePointer
    } forKey:@"trigger"];
    
    // 忽略掉系统的controller
    NSArray *ignoreCls = @[
        NSStringFromClass([UIAlertController class]),
        @"_UIAlertControllerTextFieldViewController"
    ];
    
    NSMutableArray *leaksItems = [NSMutableArray array];
    for (UIViewController *ctrlT in ctrls) {
        if (![ctrlT isKindOfClass:UIViewController.class] ||
            [ignoreCls containsObject:NSStringFromClass([ctrlT class])]) {
            continue;
        }
        
        NSPointerArray *pointer = [NSPointerArray weakObjectsPointerArray];
        [pointer addPointer:(__bridge void * _Nullable)(ctrlT)];
        
        [leaksItems addObject:@{
            @"desc": [ctrlT description]?:(ctrlT.title?:@""),
            @"class": NSStringFromClass([ctrlT class])?:@"",
            @"address": [NSString stringWithFormat:@"%p", ctrlT],
            @"point": pointer,
        }];
    }
    if (leaksItems.count == 0) {
        return nil;
    }
    [resMap setObject:leaksItems.copy forKey:@"leaks"];
    
    return resMap.copy;
}
- (void)checkLeaked_delay_controller:(NSArray *)leaks{
    if (!leaks || ![leaks isKindOfClass:NSArray.class] || leaks.count == 0) {
        return;
    }
    
    // 加入弱引用表
    [self.lock lock];
    [self.leak_ctrls addObjectsFromArray:leaks.copy];
    [self.lock unlock];
    
    // 延时检查是否释放
    [self performSelector:@selector(checkLeaked_controller:) withObject:leaks.copy afterDelay:2.0];
}
- (void)checkLeaked_controller:(NSArray *)leaks{
    NSArray *resLeaks = [self fetchLeak_controller:leaks];
    [self throwLeak_controller:resLeaks];
}
- (void)throwLeak_controller:(NSArray *)leaks{
    if (!leaks || ![leaks isKindOfClass:NSArray.class] || leaks.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSDictionary *leak in leaks) {
            [self zh_test_addLeaks:leak];
        }
    });
}
- (NSArray *)fetchLeak_controller_all{
    NSArray *res = nil;
    [self.lock lock];
    res = self.leak_ctrls.copy;
    [self.lock unlock];
    return [self fetchLeak_controller:res];
}
- (NSArray *)fetchLeak_controller:(NSArray *)leaks{
    if (!leaks || ![leaks isKindOfClass:NSArray.class] || leaks.count == 0) {
        return nil;
    }
    // 剔除ios原生对象 防止json string化失败
    NSMutableArray *resLeaks = [NSMutableArray array];
    
    for (NSDictionary *leak in leaks) {
        @autoreleasepool {
            NSMutableDictionary *newLeak = [NSMutableDictionary dictionary];
            NSMutableArray *newItems = [NSMutableArray array];
            
            NSMutableDictionary *trigger = [[leak objectForKey:@"trigger"] mutableCopy];
            [trigger removeObjectForKey:@"point"];
            NSArray *items = [leak objectForKey:@"leaks"];
            
            for (NSDictionary *item in items) {
                @autoreleasepool {
                    NSMutableDictionary *newItem = [item mutableCopy];
                    NSPointerArray *pointer = [newItem objectForKey:@"point"];
                    [pointer addPointer:NULL];
                    [pointer compact];
                    [newItem removeObjectForKey:@"point"];
                    if (pointer.allObjects.count > 0) {
                        [newItems addObject:newItem.copy];
                    }
                }
            }
            if (newItems.count > 0) {
                [newLeak setObject:trigger.copy forKey:@"trigger"];
                [newLeak setObject:newItems.copy forKey:@"leaks"];
                [newLeak setObject:[leak objectForKey:@"time"]?:@"" forKey:@"time"];
                [resLeaks addObject:newLeak.copy];
            }
        }
    }
    return resLeaks.copy;
}
- (NSArray *)fetchController_child:(UIViewController *)ctrl{
    NSMutableArray *res = [NSMutableArray array];
    if ([ctrl isKindOfClass:UIViewController.class]) {
        [res addObject:ctrl];
        for (UIViewController *subCtrl in ctrl.childViewControllers) {
            [res addObjectsFromArray:[self fetchController_child:subCtrl]];
        }
    }
    return res.copy;
}
- (NSMutableArray *)leak_ctrls{
    if (!_leak_ctrls) {
        _leak_ctrls = [NSMutableArray array];
    }
    return _leak_ctrls;
}

#pragma mark - share

- (instancetype)init{
    if (self = [super init]) {
        // 只加载一次的资源
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self.lock = [[NSLock alloc] init];
            [self crash_capture];
        });
    }
    return self;
}
static id _instance;
+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

#pragma mark - monitor

- (void)startMonitorMpLog{
}
- (void)stopMonitorMpLog{
}

- (void)zh_log{
    [ZHDPMg() zh_test_addLog];
}

#pragma mark - data

- (void)zh_test_addLog{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return;
    }
    
    __block ZHDPOutputType colorType = ZHDPOutputType_Log;
    
    //运行js解析  可能存在js对象 原生无法打印
    JSContext *context = nil;
    NSString *parseFuncName = @"zh_sdk_ios_parseJSObjToNativeValue";
    NSString *parseErrorDesc = @"只接收纯数据输出, 当前数据中包含js对象, 原生解析失败";
    JSValue *parseFunc = context ? [context objectForKeyedSubscript:parseFuncName] : nil;
    if (parseFunc) {
        if (parseFunc.isUndefined || !parseFunc.isObject) {
            [context evaluateScript:[NSString stringWithFormat:@"var %@ = function (params) {try {const res = JSON.parse(JSON.stringify(params));return res;} catch (error) {return '%@';}};", parseFuncName, parseErrorDesc]];
            parseFunc = [context objectForKeyedSubscript:parseFuncName];
        }
    }

    // 以下代码不可切换线程执行   JSContext在哪个线程  就在哪个线程执行   否则线程锁死
    NSArray *args = [JSContext currentArguments];
    NSMutableArray *resDatas = [NSMutableArray array];
    NSMutableArray *resTypes = [NSMutableArray array];
    
    NSArray *parseRes = [ZHDPMg() parseJsData:context params:args forceJsParse:NO];
    for (NSDictionary *parse in parseRes) {
        @autoreleasepool {
            if (!parse || ![parse isKindOfClass:NSDictionary.class] || parse.allKeys.count == 0) {
                continue;
            }
            [resTypes addObject:parse[@"type"]?:@"未知数据类型"];
            [resDatas addObject:parse[@"data"]?:@"未知数据,解析失败"];
            if ([parse[@"error"] boolValue]) {
                colorType = ZHDPOutputType_Error;
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_addLogSafe:colorType args:resDatas.copy argTypes:resTypes.copy];
    });
}
- (void)zh_test_addLogSafe:(ZHDPOutputType)colorType args:(NSArray *)args argTypes:(NSArray *)argTypes{
    
    ZHDPManager *dpMg = ZHDPMg();
    
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    
//    NSArray *args = [JSContext currentArguments];
    if (!args || args.count <= 0) {
        return;
    }
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = @"App";
    appItem.appName = @"App";
    
    // 此条日志的过滤信息
    ZHDPFilterItem *filterItem = [[ZHDPFilterItem alloc] init];
    filterItem.appItem = appItem;
    filterItem.page = nil;
    ZHDPOutputItem *outputItem = [[ZHDPOutputItem alloc] init];
    outputItem.type = colorType;
    filterItem.outputItem = outputItem;
    
    // 内容
    NSInteger count = args.count;
    CGFloat datePercent = [dpMg dateW] / [dpMg basicW];
    CGFloat freeW = ([dpMg basicW] - [dpMg dateW]) * 1.0 / (count * 1.0);
    CGFloat otherPercent = freeW / [dpMg basicW];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
    
    // 添加时间
    CGFloat X = 0;
    NSString *dateStr = [[dpMg dateFormat] stringFromDate:[NSDate date]];
    ZHDPListColItem *colItem = [self createColItem:dateStr percent:datePercent X:X colorType:colorType];
    [colItems addObject:colItem];
    X = CGRectGetMaxX(colItem.rectValue.CGRectValue);

    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        
        // 不要移除沙盒地址  可能小程序就要打印个绝对路径
//        NSString *detail = [self removeAppSandBox:[self parseNativeObjToString:title]];
        NSString *detail = [self parseNativeObjToString:title];
        // 添加参数
        colItem = [self createColItem:detail percent:otherPercent X:X colorType:colorType];
        [colItems addObject:colItem];
        X = CGRectGetMaxX(colItem.rectValue.CGRectValue);

        [titles addObject:[NSString stringWithFormat:@"参数%ld  %@  : ", i, argTypes[i]]];
        [descs addObject:detail?:@""];
    }
    
    // 弹窗详情数据
    ZHDPListDetailItem *item = [self createDetailItem:@"参数" keys:titles values:descs];
    [detailItems addObject:item];
        
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;

    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.filterItem = filterItem;
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        NSMutableString *str = [NSMutableString string];
        [str appendFormat:@"%@\n", dateStr];
        [str appendString:[self createDetailItemsString:detailItems]];
        return str.copy;
    };
    // 添加数据
    [self addSecItemToList:ZHDPListLog.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListLog.class appItem:appItem secItem:secItem colorType:colorType];
}

- (void)zh_test_addNetwork:(NSDate *)startDate
                       url:(NSURL *)url
                    method:(NSString *)method
                   headers:(NSDictionary *)headers
                  httpBody:(NSData *)httpBody
            httpBodyStream:(NSData *)httpBodyStream
                  response:(NSURLResponse *)response
              responseData:(NSData *)responseData{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return;
    }
    // 来自fund-cli调试下载的js文件 不收集
    if ([headers objectForKey:@"fund-cli-socket-request-header-key"]) {
        return;
    }
    
    NSHTTPURLResponse *httpResponse = nil;
    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
        httpResponse = (NSHTTPURLResponse*)response;
    }
    NSDictionary *responseHeaders = httpResponse.allHeaderFields.copy;
    NSInteger statusCode = httpResponse.statusCode;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_addNetworkSafe:startDate url:url method:method headers:headers httpBody:httpBody httpBodyStream:httpBodyStream responseHeaders:responseHeaders responseCode:statusCode responseData:responseData];
    });
}
- (void)zh_test_addNetworkSafe:(NSDate *)startDate
                           url:(NSURL *)url
                        method:(NSString *)method
                       headers:(NSDictionary *)headers
                      httpBody:(NSData *)httpBody
                httpBodyStream:(NSData *)httpBodyStream
               responseHeaders:(NSDictionary *)responseHeaders
                  responseCode:(NSInteger)responseCode
                  responseData:(NSData *)responseData{

    ZHDPManager *dpMg = ZHDPMg();
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }

    NSDictionary *paramsInBody = [self parseRequestBodyDataToNativeObj:httpBody];
    NSDictionary *paramsInBodyStream = [self parseRequestBodyDataToNativeObj:httpBodyStream];

    NSString *urlStr = url.absoluteString;
    NSString *host = headers[@"host"];
    if (host && [host isKindOfClass:NSString.class] && host.length > 0) {
        urlStr = [urlStr stringByReplacingOccurrencesOfString:url.host withString:host];
    }

    NSMutableDictionary *paramsInUrl = [NSMutableDictionary dictionary];
    NSURLComponents *comp = [NSURLComponents componentsWithString:urlStr];
    for (NSURLQueryItem *item in comp.queryItems) {
        if (item.name.length && item.value.length) {
            [paramsInUrl setObject:item.value forKey:item.name];
        }
    }
    
    NSString *urlStrRemoveParams = url.absoluteString;
    if ([url query].length > 0) {
        urlStrRemoveParams = [urlStrRemoveParams stringByReplacingOccurrencesOfString:[url query] withString:@""];
    }
    
    NSString *statusCode = [NSString stringWithFormat:@"%ld",responseCode];
    ZHDPOutputType colorType = ((statusCode.integerValue < 200 || statusCode.integerValue >= 300) ? ZHDPOutputType_Error :  ZHDPOutputType_Log);

    NSDate *endDate = [NSDate date];
    NSTimeInterval startTimeDouble = [startDate timeIntervalSince1970];
    NSTimeInterval endTimeDouble = [endDate timeIntervalSince1970];
    NSTimeInterval durationDouble = fabs(endTimeDouble - startTimeDouble);
    
    NSString *duration = [NSString stringWithFormat:@"%.3fms", durationDouble * 1000];
    NSString *appId = nil;
    NSString *appEnv = nil;
    NSString *appPath = nil;
    
    NSString *referer = headers[@"Referer"];
    if (referer && [referer isKindOfClass:NSString.class] &&
        referer.length > 0 && [referer containsString:@"https://mpservice.com"]) {
        NSURL *url = [NSURL URLWithString:referer];
        NSArray *coms = url.pathComponents;
        for (NSUInteger i = 0; i< coms.count; i++) {
            if (i == 1) {
                appId = coms[i];
            }else if (i == 2){
                appEnv = coms[i];
            }else if (i >= 3){
                NSMutableArray *newComs = [coms mutableCopy];
                [newComs removeObjectsInRange:NSMakeRange(0, 3)];
                appPath = [NSString pathWithComponents:newComs.copy];
                break;
            }
        }
    }
    
    // 哪个应用的数据  默认App的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = @"App";
    appItem.appName =  @"App";
    
    // 此条日志的过滤信息
    ZHDPFilterItem *filterItem = [[ZHDPFilterItem alloc] init];
    filterItem.appItem = appItem;
    filterItem.page = appPath;
    ZHDPOutputItem *outputItem = [[ZHDPOutputItem alloc] init];
    outputItem.type = colorType;
    filterItem.outputItem = outputItem;
    
    NSArray *args = @[urlStrRemoveParams?:@"", method?:@"", statusCode?:@""];
    // 内容
    NSInteger count = args.count;
    NSArray *otherPercents = @[@(0.77), @(0.13), @(0.10)];

    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    
    CGFloat X = 0;
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSNumber *percent = otherPercents[i];
        
        NSString *detail = [self parseNativeObjToString:title];
        // 添加参数
        ZHDPListColItem *colItem = [self createColItem:detail percent:percent.floatValue X:X colorType:colorType];
        [colItems addObject:colItem];
        X += colItem.rectValue.CGRectValue.size.width;
    }

    // 弹窗详情数据
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    ZHDPListDetailItem *item = [self createDetailItem:@"简要" keys:@[@"URL:", @"Method:", @"Status Code:", @"Start Time:", @"End Time:", @"Duration:"] values:@[
        urlStr?:@"",
        method?:@"",
        statusCode?:@"",
        [[dpMg dateByFormat:@"yyyy-MM-dd HH:mm:ss.SSS"] stringFromDate:startDate]?:@"",
        [[dpMg dateByFormat:@"yyyy-MM-dd HH:mm:ss.SSS"] stringFromDate:endDate]?:@"",
        duration?:@""
    ]];
    [detailItems addObject:item];
    
    item = [self createDetailItem:@"请求参数" keys:@[@"Request Query (In URL):", @"Request Query (In Body):", @"Request Query (In BodyStream):"] values:@[
        (^NSString *(){
        if (paramsInUrl.allKeys.count == 0) {
            return @"";
        }
        return [self parseNativeObjToString:paramsInUrl]?:@"";
    })(),
        (^NSString *(){
        NSString *res = [self parseNativeObjToString:paramsInBody];
        return res?:@"";
    })(),
        (^NSString *(){
        NSString *res = [self parseNativeObjToString:paramsInBodyStream];
        return res?:@"";
    })()]];
    [detailItems addObject:item];
    
    item = [self createDetailItem:@"响应数据" keys:@[@"Response Data:"] values:@[
        (^NSString *(){
        NSString *res = [self parseNativeObjToString:responseData];
        return res?:@"";
    })()
    ]];
    [detailItems addObject:item];
    
    item = [self createDetailItem:@"请求头" keys:@[@"Request Headers:"] values:@[
        [self parseNativeObjToString:headers?:@{}]?:@""
    ]];
    [detailItems addObject:item];
    
    item = [self createDetailItem:@"响应头" keys:@[@"Response Headers:"] values:@[
        [self parseNativeObjToString:responseHeaders?:@{}]?:@""
    ]];
    [detailItems addObject:item];
    
    item = [self createDetailItem:@"来源" keys:@[@"小程序信息:"] values:@[[self parseNativeObjToString:@{@"appName": appItem.appName?:@"", @"appId": appItem.appId?:@"", @"path": appPath?:@""}]?:@""]];
    [detailItems addObject:item];
    
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;

    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.filterItem = filterItem;
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        return [self createDetailItemsString:detailItems];
    };
    // 添加数据
    [self addSecItemToList:ZHDPListNetwork.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListNetwork.class appItem:appItem secItem:secItem colorType:colorType];
}

- (void)zh_test_reloadStorage{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_reloadStorageSafe];
    });
}
- (void)zh_test_reloadStorageSafe{
    ZHDPManager *dpMg = ZHDPMg();
    
    // 从全局数据管理中移除所有storage数据
    NSArray <ZHDPAppDataItem *> *appDataItems = [dpMg.dataTask fetchAllAppDataItems];
    for (ZHDPAppDataItem *appDataItem in appDataItems) {
        [dpMg.dataTask cleanAllItems:appDataItem.storageItems];
    }
    
    // 读取storage数据
    NSArray *arr = @[
        @{@"test": @"ffffffffffffff"}
    ];
    for (NSDictionary *info in arr) {
        // 载入新数据
        [self zh_test_addStorageSafe:info];
    }
    
}
- (void)zh_test_addStorageSafe:(NSDictionary *)storage{
    ZHDPManager *dpMg = ZHDPMg();
    
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    
    if (!storage || ![storage isKindOfClass:NSDictionary.class] || storage.allKeys.count == 0) {
        return;
    }
    
    [storage enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        [self zh_test_addStorageSafeSingle:@[key, obj]];
    }];
}
- (void)zh_test_addStorageSafeSingle:(NSArray *)args{
    ZHDPManager *dpMg = ZHDPMg();
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = @"App";
    appItem.appName = @"App";
    
    // 此条日志的过滤信息
    ZHDPFilterItem *filterItem = [[ZHDPFilterItem alloc] init];
    filterItem.appItem = appItem;
    filterItem.page = nil;
    ZHDPOutputItem *outputItem = [[ZHDPOutputItem alloc] init];
    outputItem.type = ZHDPOutputType_Log;
    filterItem.outputItem = outputItem;
    
    // 内容
    NSInteger count = args.count;
    NSArray *otherPercents = @[@(0.3), @(0.7)];

    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
        
    CGFloat X = 0;
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSNumber *percent = otherPercents[i];
        
        NSString *detail = [self parseNativeObjToString:title];
        // 添加参数
        ZHDPListColItem *colItem = [self createColItem:detail percent:percent.floatValue X:X colorType:ZHDPOutputType_Log];
        [colItems addObject:colItem];
        X += colItem.rectValue.CGRectValue.size.width;

        if (detail) [descs addObject:detail];
    }
    
    // 弹窗详情数据
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    ZHDPListDetailItem *item = [self createDetailItem:@"数据" keys:@[@"Key:", @"Value:"] values:descs];
    [detailItems addObject:item];
        
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;

    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.filterItem = filterItem;
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        return [self createDetailItemsString:detailItems];
    };
    // 添加数据
    [self addSecItemToList:ZHDPListStorage.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListStorage.class appItem:appItem secItem:secItem colorType:ZHDPOutputType_Log];
}
- (void)zh_test_deleteStorageStore:(NSArray <ZHDPListSecItem *> *)secItems{
    for (ZHDPListSecItem *secItem in secItems) {
        @autoreleasepool {
            if (secItem.rowItems.count == 0 ||  secItem.rowItems.firstObject.colItems.count == 0) {
                continue;
            }
            ZHDPListColItem *colItem = secItem.rowItems.firstObject.colItems.firstObject;
            NSString *key = colItem.attTitle.string;
            NSMutableDictionary *res = @{@"key":((key && [key isKindOfClass:NSString.class] && key.length) ? key : @"")}.mutableCopy;
            [res addEntriesFromDictionary:@{
                @"level": colItem.extraInfo[@"level"]?:@"",
                @"prefix": colItem.extraInfo[@"prefix"]?:@""
            }];
//            [[ZHStorageManager shareInstance] removeStorageSync:res.copy appId:colItem.extraInfo[@"appId"]?:@""];
        }
    }
}
- (void)zh_test_deleteStorageStoreByData:(NSArray *)secItemsData{
    for (NSDictionary *secItem in secItemsData) {
        @autoreleasepool {
            NSArray *rowItems = [secItem objectForKey:@"rowItems"];
            if (rowItems.count == 0) {
                continue;
            }
            NSArray *colItems = [rowItems.firstObject objectForKey:@"colItems"];
            if (colItems.count == 0) {
                continue;
            }
            NSString *key = [colItems.firstObject objectForKey:@"title"];
            NSDictionary *extraInfo = [colItems.firstObject objectForKey:@"extraInfo"];
            
            NSMutableDictionary *res = @{@"key":((key && [key isKindOfClass:NSString.class] && key.length) ? key : @"")}.mutableCopy;
            [res addEntriesFromDictionary:@{
                @"level": extraInfo[@"level"]?:@"",
                @"prefix": extraInfo[@"prefix"]?:@""
            }];
//            [[ZHStorageManager shareInstance] removeStorageSync:res.copy appId:extraInfo[@"appId"]?:@""];
        }
    }
}

- (void)zh_test_addLeaks:(NSDictionary *)leakMap{
    if (!leakMap || ZHDPMg().status != ZHDPManagerStatus_Open) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) return;
        [self zh_test_addLeaksSafe:ZHDPOutputType_Error leakMap:leakMap];
    });
}
- (void)zh_test_addLeaksSafe:(ZHDPOutputType)colorType leakMap:(NSDictionary *)leakMap{
    ZHDPManager *dpMg = ZHDPMg();
    
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return;
    }
    if (!leakMap || ![leakMap isKindOfClass:NSDictionary.class] || leakMap.allKeys.count == 0) {
        return;
    }
    NSDictionary *trigger = [leakMap objectForKey:@"trigger"];
    NSString *time = [leakMap objectForKey:@"time"];
    NSString *triggerSource = [NSString stringWithFormat:@"[%@ %@]", [trigger objectForKey:@"class"], [trigger objectForKey:@"function"]];
    NSArray *leaks = [leakMap objectForKey:@"leaks"];
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = @"App";
    appItem.appName = @"App";
        
    // 此条日志的过滤信息
    ZHDPFilterItem *filterItem = [[ZHDPFilterItem alloc] init];
    filterItem.appItem = appItem;
    filterItem.page = nil;
    ZHDPOutputItem *outputItem = [[ZHDPOutputItem alloc] init];
    outputItem.type = colorType;
    filterItem.outputItem = outputItem;
    
    // 内容
    NSArray *args = @[triggerSource];
    NSInteger count = args.count;
    CGFloat datePercent = [dpMg dateW] / [dpMg basicW];
    CGFloat freeW = ([dpMg basicW] - [dpMg dateW]) * 1.0 / (count * 1.0);
    CGFloat otherPercent = freeW / [dpMg basicW];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    
    // 添加时间
    CGFloat X = 0;
    NSString *dateStr = [[dpMg dateFormat] stringFromDate:[NSDate date]];
    ZHDPListColItem *colItem = [self createColItem:dateStr percent:datePercent X:X colorType:colorType];
    [colItems addObject:colItem];
    X += colItem.rectValue.CGRectValue.size.width;
        
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSString *detail = [self parseNativeObjToString:title];
        // 添加参数
        colItem = [self createColItem:detail percent:otherPercent X:X colorType:colorType];
        [colItems addObject:colItem];
        X += colItem.rectValue.CGRectValue.size.width;
    }
    
    // 弹窗详情数据
    ZHDPListDetailItem *item = [self createDetailItem:@"简要" keys:@[[NSString stringWithFormat:@"调用函数 (%@) :", time], @"触发源:", @"内存泄露列表"] values:@[triggerSource, [self parseNativeObjToString:trigger]?:@"", [self parseNativeObjToString:leaks]?:@""]];
    [detailItems addObject:item];
        
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;
    
    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.filterItem = filterItem;
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        NSMutableString *str = [NSMutableString string];
        [str appendFormat:@"%@\n", dateStr];
        [str appendString:[self createDetailItemsString:detailItems]];
        return str.copy;
    };
    
    // 添加数据
    [self addSecItemToList:ZHDPListLeaks.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListLeaks.class appItem:appItem secItem:secItem colorType:colorType];
}

- (void)zh_test_addCrash{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) return;
        
        NSArray *crashs = [self crash_fetchLastFiles];
        NSArray *crashContents = [self crash_read:crashs];
        [self crash_move:crashs];
        for (NSDictionary *item in crashContents) {
            [self zh_test_addCrashSafe:ZHDPOutputType_Error crash:item];
        }
    });
}
- (void)zh_test_addCrashSafe:(ZHDPOutputType)colorType crash:(NSDictionary *)crash{
    ZHDPManager *dpMg = ZHDPMg();
    
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return;
    }
    if (!crash || ![crash isKindOfClass:NSDictionary.class] || crash.allKeys.count == 0) {
        return;
    }
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = @"App";
    appItem.appName = @"App";
        
    // 此条日志的过滤信息
    ZHDPFilterItem *filterItem = [[ZHDPFilterItem alloc] init];
    filterItem.appItem = appItem;
    filterItem.page = nil;
    ZHDPOutputItem *outputItem = [[ZHDPOutputItem alloc] init];
    outputItem.type = colorType;
    filterItem.outputItem = outputItem;
    
    // 内容
    NSArray *args = @[crash[@"reason"]?:@""];
    NSInteger count = args.count;
    CGFloat datePercent = [dpMg dateW] / [dpMg basicW];
    CGFloat freeW = ([dpMg basicW] - [dpMg dateW]) * 1.0 / (count * 1.0);
    CGFloat otherPercent = freeW / [dpMg basicW];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    
    // 添加时间
    CGFloat X = 0;
    NSString *dateStr = [[dpMg dateFormat] stringFromDate:[NSDate date]];
    ZHDPListColItem *colItem = [self createColItem:dateStr percent:datePercent X:X colorType:colorType];
    [colItems addObject:colItem];
    X += colItem.rectValue.CGRectValue.size.width;
        
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSString *detail = [self parseNativeObjToString:title];
        // 添加参数
        colItem = [self createColItem:detail percent:otherPercent X:X colorType:colorType];
        [colItems addObject:colItem];
        X += colItem.rectValue.CGRectValue.size.width;
    }
    
    // 弹窗详情数据
    ZHDPListDetailItem *item = [self createDetailItem:@"简要" keys:@[@"name:", @"reason:", @"time:", @"userInfo:"] values:@[
        [self parseNativeObjToString:crash[@"name"]]?:@"",
        [self parseNativeObjToString:crash[@"reason"]]?:@"",
        [self parseNativeObjToString:crash[@"time"]]?:@"",
        [self parseNativeObjToString:crash[@"userInfo"]]?:@""]];
    [detailItems addObject:item];
    
    item = [self createDetailItem:@"崩溃栈" keys:@[@"callStackSymbols:"] values:@[[self parseNativeObjToString:crash[@"callStackSymbols"]]?:@""]];
    [detailItems addObject:item];
    
    item = [self createDetailItem:@"App信息" keys:@[@"版本信息:"] values:@[[self parseNativeObjToString:crash[@"app"]]?:@""]];
    [detailItems addObject:item];
        
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;
    
    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.filterItem = filterItem;
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        NSMutableString *str = [NSMutableString string];
        [str appendFormat:@"%@\n", dateStr];
        [str appendString:[self createDetailItemsString:detailItems]];
        return str.copy;
    };
    
    // 添加数据
    [self addSecItemToList:ZHDPListCrash.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListCrash.class appItem:appItem secItem:secItem colorType:colorType];
}

- (void)zh_test_addMemoryWarning:(UIViewController *)controller params:(NSDictionary *)params{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) return;
        [self zh_test_addMemoryWarningSafe:ZHDPOutputType_Warning controller:controller params:params];
    });
}
- (void)zh_test_addMemoryWarningSafe:(ZHDPOutputType)colorType controller:(UIViewController *)controller params:(NSDictionary *)params{
    ZHDPManager *dpMg = ZHDPMg();
    
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return;
    }
    NSMutableDictionary *resParams = [NSMutableDictionary dictionary];
    if (params && [params isKindOfClass:NSDictionary.class]) {
        [resParams addEntriesFromDictionary:params];
    }
    
    NSDictionary *ctrlPrams = nil;
    if (controller) {
        ctrlPrams = @{
            @"controller": [controller description]?:@""
        };
    }
    if (ctrlPrams && [ctrlPrams isKindOfClass:NSDictionary.class]) {
        [resParams addEntriesFromDictionary:ctrlPrams];
    }
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = @"App";
    appItem.appName = @"App";
        
    // 此条日志的过滤信息
    ZHDPFilterItem *filterItem = [[ZHDPFilterItem alloc] init];
    filterItem.appItem = appItem;
    filterItem.page = nil;
    ZHDPOutputItem *outputItem = [[ZHDPOutputItem alloc] init];
    outputItem.type = colorType;
    filterItem.outputItem = outputItem;
    
    // 内容
    NSArray *args = @[[self parseNativeObjToString:resParams.copy]?:@""];
    NSInteger count = args.count;
    CGFloat datePercent = [dpMg dateW] / [dpMg basicW];
    CGFloat freeW = ([dpMg basicW] - [dpMg dateW]) * 1.0 / (count * 1.0);
    CGFloat otherPercent = freeW / [dpMg basicW];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    
    // 添加时间
    CGFloat X = 0;
    NSString *dateStr = [[dpMg dateFormat] stringFromDate:[NSDate date]];
    ZHDPListColItem *colItem = [self createColItem:dateStr percent:datePercent X:X colorType:colorType];
    [colItems addObject:colItem];
    X += colItem.rectValue.CGRectValue.size.width;
        
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSString *detail = [self parseNativeObjToString:title];
        // 添加参数
        colItem = [self createColItem:detail percent:otherPercent X:X colorType:colorType];
        [colItems addObject:colItem];
        X += colItem.rectValue.CGRectValue.size.width;
    }
    
    // 弹窗详情数据
    ZHDPListDetailItem *item = [self createDetailItem:@"简要" keys:@[@"警告信息:"] values:args];
    [detailItems addObject:item];
        
    // 每一组中的每行数据
    ZHDPListRowItem *rowItem = [[ZHDPListRowItem alloc] init];
    rowItem.colItems = colItems.copy;
    
    // 每一组数据
    ZHDPListSecItem *secItem = [[ZHDPListSecItem alloc] init];
    secItem.filterItem = filterItem;
    secItem.enterMemoryTime = [[NSDate date] timeIntervalSince1970];
    secItem.open = YES;
    secItem.colItems = @[];
    secItem.rowItems = @[rowItem];
    secItem.detailItems = detailItems.copy;
    secItem.pasteboardBlock = ^NSString *{
        NSMutableString *str = [NSMutableString string];
        [str appendFormat:@"%@\n", dateStr];
        [str appendString:[self createDetailItemsString:detailItems]];
        return str.copy;
    };
    
    // 添加数据
    [self addSecItemToList:ZHDPListMemoryWarning.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListMemoryWarning.class appItem:appItem secItem:secItem colorType:colorType];
}
@end

