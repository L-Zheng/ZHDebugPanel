//
//  ZHDPManager.m
//  ZHJSNative
//
//  Created by EM on 2021/5/27.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPManager.h"
#import <CoreText/CoreText.h>
#import "ZHDPContent.h"// 内容列表容器
#import "ZHDPListLog.h"// log列表
#import "ZHDPListNetwork.h"// network列表
#import "ZHDPListStorage.h"// storage列表
#import "ZHDPListMemory.h"// Memory列表
#import "ZHDPListIM.h"// im列表
#import "ZHDPListException.h"// Exception列表

@interface ZHDPManager (){
    CFURLRef _originFontUrl;//注册字体Url
    CTFontDescriptorRef _descriptor;//注册字体Descriptor
}
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,strong) NSDateFormatter *dateFormat;
@property (nonatomic,copy) void (^clickToastBlock) (void);
@property (nonatomic,assign) BOOL debugPanelH5Disable;
@property (nonatomic,strong) ZHDPNetworkTask *networkTask;
@property (nonatomic,strong) NSLock *lock;
@end

@implementation ZHDPManager

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
    return [str boundingRectWithSize:CGSizeMake(basicW, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [self defaultFont]} context:nil].size.width;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveImMessage:) name:@"ZHSDKImMessageToConsoleNotification" object:nil];
    
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
    [self.window hideDebugPanel];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZHSDKImMessageToConsoleNotification" object:nil];
    
    if (!_weakWindow) return;
    self.window.hidden = YES;
    self.window = nil;
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
    return keyWindow.isKeyWindow ? keyWindow : nil;
}
- (UIEdgeInsets)fetchKeyWindowSafeAreaInsets{
    // 只是获取window的safeAreaInsets  不需要window成为keyWindow
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *window in windows) {
            if (window.windowLevel == UIWindowLevelNormal){
                keyWindow = window;
                break;
            }
        }
    }
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = [keyWindow safeAreaInsets];
    }
    return safeAreaInsets;
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
    [self.window hideDebugPanel];
}
- (void)switchDebugPanel{
    if (!_window) return;
    [self.window hideFloat];
    [self.window showDebugPanel];
    
    if (0) {
        [ZHDPMg() showToast:@"点击以使用同步输出" duration:2.0 clickBlock:^{
            [ZHDPMg() switchFloat];
        } complete:nil];
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
    return [UIFont systemFontOfSize:14];
}
- (UIFont *)defaultBoldFont{
    return [UIFont boldSystemFontOfSize:14];
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
    
    if ([colorString hasSuffix:@"color"]) {
        NSString *selectorStr = [colorString stringByReplacingOccurrencesOfString:@"color" withString:@"Color"];
        NSMethodSignature *signature = [[UIColor class] methodSignatureForSelector:NSSelectorFromString(selectorStr)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = [UIColor class];
        invocation.selector = NSSelectorFromString(selectorStr);
        [invocation invoke];
        
        UIColor *color = nil;
        [invocation getReturnValue:&color];
        
        return color;
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

- (void)showToast:(NSString *)title duration:(NSTimeInterval)duration clickBlock:(void (^__nullable) (void))clickBlock complete:(void (^__nullable) (void))complete{
    self.clickToastBlock = clickBlock;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    
    label.userInteractionEnabled = YES;
    UIGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickToast)];
    [label addGestureRecognizer:tapGes];

    label.text = title;
    label.font = [self defaultFont];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.adjustsFontSizeToFitWidth = YES;
    label.textColor = [self selectColor];
//    label.alpha = 0.7;
    label.backgroundColor = [UIColor whiteColor];
    label.layer.masksToBounds = YES;
    label.clipsToBounds = YES;
    
    UIView *container = self.window.debugPanel;
    CGSize size = [label.text boundingRectWithSize:CGSizeMake(container.bounds.size.width - 10, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: label.font} context:nil].size;
    size.width += 10;
    size.height += 10;
    if (size.width < 150) size.width = 150;
    if (size.height < 30) size.height = 30;
    CGFloat X = (container.bounds.size.width - size.width) * 0.5;
    
    CGRect startFrame = (CGRect){{X, -size.height}, size};
    CGRect endFrame = (CGRect){{X, 5}, size};
    
    label.layer.cornerRadius = size.height * 0.5;
    [container addSubview:label];
    
    label.frame = startFrame;
    
    [UIView animateWithDuration:0.25 animations:^{
        label.frame = endFrame;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{
                label.frame = startFrame;
            } completion:^(BOOL finished) {
                [label removeFromSuperview];
            }];
            if (complete) complete();
        });
    }];
}
- (void)clickToast{
    if (self.clickToastBlock) {
        self.clickToastBlock();
        self.clickToastBlock = nil;
    }
}

#pragma mark - data

/**JSContext中：js类型-->JSValue类型 对应关系
 Date：[JSValue toDate]=[NSDate class]
 function：[JSValue toObject]=[NSDictionary class]    [jsValue isObject]=YES
 null：[JSValue toObject]=[NSNull null]
 undefined：[JSValue toObject]=nil
 boolean：[JSValue toObject]=@(YES) or @(NO)  [NSNumber class]
 number：[JSValue toObject]= [NSNumber class]
 string：[JSValue toObject]= [NSString class]   [jsValue isObject]=NO
 array：[JSValue toObject]= [NSArray class]    [jsValue isObject]=YES
 json：[JSValue toObject]= [NSDictionary class]    [jsValue isObject]=YES
 */
- (id)jsValueToNative:(JSValue *)jsValue{
    if (!jsValue) return nil;
    if (@available(iOS 9.0, *)) {
        if (jsValue.isDate) {
            return [jsValue toDate];
        }
        if (jsValue.isArray) {
            return [jsValue toArray];
        }
    }
    if (@available(iOS 13.0, *)) {
        if (jsValue.isSymbol) {
            return nil;
        }
    }
    if (jsValue.isNull) {
        return [NSNull null];
    }
    if (jsValue.isUndefined) {
        return @"Undefined";
    }
    if (jsValue.isBoolean){
        return [jsValue toBool] ? @"true" : @"false";
    }
    if (jsValue.isString || jsValue.isNumber){
        return [jsValue toObject];
    }
    if (jsValue.isObject){
        return [jsValue toObject];
    }
    return [jsValue toObject];
}
- (NSString *)jsonToString:(id)json{
    if (!json) {
        return nil;
    }
    if ([json isKindOfClass:NSArray.class] || [json isKindOfClass:NSDictionary.class]) {
        NSString *res = nil;
        @try {
            NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
            res = (data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil);
        } @catch (NSException *exception) {
        } @finally {
        }
        return res;
    }
    return json;
}
- (void)convertToString:(id)title block:(void (^) (NSString *conciseStr, NSString *detailStr))block{
    if (!block) {
        return;
    }
    if (!title) {
        block(nil, nil);
        return;
    }
    if ([title isKindOfClass:NSDate.class]) {
        block([(NSDate *)title description], [(NSDate *)title description]);
        return;
    }
    if ([title isKindOfClass:NSArray.class]) {
        block(@"[Object Array]", [self jsonToString:title] ?: @"[Object Array]");
        return;
    }
    if ([title isKindOfClass:NSNull.class]) {
        block(@"[Object Null]", @"[Object Null]");
        return;
    }
    if ([title isKindOfClass:NSString.class]) {
        block(title, title);
        return;
    }
    if ([title isKindOfClass:NSNumber.class]) {
        block([NSString stringWithFormat:@"%@", title], [NSString stringWithFormat:@"%@", title]);
        return;
    }
    if ([title isKindOfClass:NSDictionary.class]) {
        block(@"[Object Object]", [self jsonToString:title] ?: @"[Object Object]");
        return;
    }
    block([title description], [title description]);
}
- (NSAttributedString *)createDetailAttStr:(NSArray *)titles descs:(NSArray *)descs{
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 5;
    for (NSUInteger i = 0; i < titles.count; i++) {
        NSString *title = [self removeEscapeCharacter:titles[i]];
        [attStr appendAttributedString:([title isKindOfClass:NSAttributedString.class] ? (NSAttributedString *)title : [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [ZHDPMg() defaultBoldFont], NSForegroundColorAttributeName: [ZHDPMg() selectColor], NSParagraphStyleAttributeName: style}])];
        if (i < descs.count){
            NSString *desc = [self removeEscapeCharacter:descs[i]];
            [attStr appendAttributedString:([desc isKindOfClass:NSAttributedString.class] ? (NSAttributedString *)desc : [[NSAttributedString alloc] initWithString:desc attributes:@{NSFontAttributeName: [ZHDPMg() defaultFont], NSForegroundColorAttributeName: [ZHDPMg() defaultColor], NSParagraphStyleAttributeName: style}])];
        }
    }
    return [[NSAttributedString alloc] initWithAttributedString:attStr];
}
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
    CGFloat width = [self basicW] * colItem.percent;
    
    CGSize fitSize = [colItem.attTitle boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
//    CGSize fitSize = [title boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [self defaultFont]} context:nil].size;
    colItem.rectValue = [NSValue valueWithCGRect:CGRectMake(X, 0, width, fitSize.height + 2 * 5)];
    
    return colItem;
}
- (id)parseObjFromData:(NSData *)data{
    if (!data || ![data isKindOfClass:NSData.class]) {
        return nil;
    }
    id res = nil;
    // 尝试json解析
    @try {
        res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
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
- (id)parseDataFromRequestBody:(NSData *)data{
    id res = [self parseObjFromData:data];
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
- (NSString *)removeEscapeCharacter:(NSString *)str{
    if (!str || ![str isKindOfClass:NSString.class] || str.length == 0) {
        return str;
    }
    return [str stringByReplacingOccurrencesOfString:@"\\" withString:@""];
}
- (void)copySecItemToPasteboard:(ZHDPListSecItem *)secItem{
    if (secItem.pasteboardBlock) {
        NSString *str = secItem.pasteboardBlock();
        // 去除转义字符
        str = [self removeEscapeCharacter:str];
        [[UIPasteboard generalPasteboard] setString:str];
        [self showToast:@"已复制，点击分享" duration:1.0 clickBlock:^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"weixin://"]];
        } complete:nil];
    }
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
    return @{
        NSStringFromClass(ZHDPListLog.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.logItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.logSpaceItem;
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
                    return appDataItem.networkSpaceItem;
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
                    return appDataItem.storageSpaceItem;
                },
                sendSocketKey: ^NSString *(void){
                    return @"storage-list";
                }
        },
        NSStringFromClass(ZHDPListMemory.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.memoryItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.memorySpaceItem;
                },
                sendSocketKey: ^NSString *(void){
                    return @"memory-list";
                }
        },
        NSStringFromClass(ZHDPListIM.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.imItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.imSpaceItem;
                },
                sendSocketKey: ^NSString *(void){
                    return @"im-list";
                }
        },
        NSStringFromClass(ZHDPListException.class): @{
                itemsKey: ^NSMutableArray *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.exceptionItems;
                },
                spaceKey: ^ZHDPDataSpaceItem *(ZHDPAppDataItem *appDataItem){
                    return appDataItem.exceptionSpaceItem;
                },
                sendSocketKey: ^NSString *(void){
                    return @"exception-list";
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
- (void)sendSocketClientSecItemToList:(Class)listClass appItem:(ZHDPAppItem *)appItem secItem:(ZHDPListSecItem *)secItem colorType:(ZHDPOutputType)colorType{
    if (!secItem) {
        return;
    }
    return;
    NSMutableArray *rowItems = [NSMutableArray array];
    for (ZHDPListRowItem *rowItem in secItem.rowItems) {
        NSMutableArray *colItems = [NSMutableArray array];
        for (ZHDPListColItem *colItem in rowItem.colItems) {
            [colItems addObject:@{
                @"title": [self removeEscapeCharacter:colItem.attTitle.string?:@""],
                @"percent": [[NSString stringWithFormat:@"%.f", colItem.percent * 100] stringByAppendingString:@"%"],
                @"color": [ZHDPOutputItem colorStrByType:colorType]?:@"#000000",
                @"extraInfo": colItem.extraInfo?:@{}
            }];
        }
        [rowItems addObject:@{
            @"colItems": colItems.copy
        }];
    }
    NSMutableArray *detailItems = [NSMutableArray array];
    for (ZHDPListDetailItem *detailItem in secItem.detailItems) {
        [detailItems addObject:@{
            @"title": [self removeEscapeCharacter:detailItem.title?:@""],
            @"content": [self removeEscapeCharacter:detailItem.content.string?:@""],
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
}

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
    if (_window && self.window.debugPanel.status == ZHDebugPanelStatus_Show) {
        ZHDPList *list = self.window.debugPanel.content.selectList;
        if ([list isKindOfClass:listClass]) {
            [list addSecItem:secItem spaceItem:spaceBlock(appDataItem)];
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
            if (1) {
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

#pragma mark - share

- (instancetype)init{
    if (self = [super init]) {
        // 只加载一次的资源
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self.lock = [[NSLock alloc] init];
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

@end

@implementation ZHDPManager (ZHPlatformTest)

#pragma mark - monitor

- (void)startMonitorMpLog{
}
- (void)stopMonitorMpLog{
}

- (void)zh_log{
    [ZHDPMg() zh_test_addLog];
}

#pragma mark - data

- (void)receiveImMessage:(NSNotification *)note{
    NSDictionary *info = note.userInfo;
    if (!info ||
        ![info isKindOfClass:NSDictionary.class] ||
        info.allKeys.count == 0) return;
    
    [self zh_test_addIM:@[info[@"type"]?:@"", info[@"data"] ?:@""]];
}

- (void)zh_test_addIM:(NSArray *)args{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_addIMSafe:args];
    });
}
- (void)zh_test_addIMSafe:(NSArray *)args{
    
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
    outputItem.type = ZHDPOutputType_Log;
    filterItem.outputItem = outputItem;
    
    // 内容
    NSInteger count = args.count;
    CGFloat freeW = [dpMg basicW] - ([dpMg marginW] * (count + 1));
    NSArray *otherPercents = @[@(0.3 * freeW / [dpMg basicW]), @(0.7 * freeW / [dpMg basicW])];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray <ZHDPListDetailItem*> *detailItems = [NSMutableArray array];
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
    
    CGFloat X = [dpMg marginW];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSNumber *percent = otherPercents[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        ZHDPListColItem *colItem = [self createColItem:detail percent:percent.floatValue X:X colorType:ZHDPOutputType_Log];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
        
        [titles addObject:@"\n"];
        [descs addObject:detail?:@""];
    }
    
    // 弹窗详情数据
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"概要";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
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
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    // 添加数据
    [self addSecItemToList:ZHDPListIM.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListIM.class appItem:appItem secItem:secItem colorType:ZHDPOutputType_Log];
}

- (void)zh_test_addLog{
    if (ZHDPMg().status != ZHDPManagerStatus_Open) {
        return;
    }
    
    ZHDPOutputType colorType = ZHDPOutputType_Log;
    
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
    NSMutableArray *res = [NSMutableArray array];
    for (JSValue *jsValue in args) {
        id parseRes = [self jsValueToNative:jsValue];
        if ([parseRes isKindOfClass:NSArray.class] || [parseRes isKindOfClass:NSDictionary.class]) {
            if (parseFunc) {
                parseRes = [[parseFunc callWithArguments:@[parseRes]] toObject];
                if (parseRes && [parseRes isKindOfClass:NSString.class] && [parseRes isEqualToString:parseErrorDesc]) {
                    colorType = ZHDPOutputType_Error;
                }
            }
        }
        [res addObject:parseRes?:@""];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_addLogSafe:colorType args:res.copy];
    });
}
- (void)zh_test_addLogSafe:(ZHDPOutputType)colorType args:(NSArray *)args{
    
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
    CGFloat freeW = ([dpMg basicW] - ([dpMg marginW] * (count + 1 + 1)) - [dpMg dateW]) * 1.0 / (count * 1.0);
    CGFloat otherPercent = freeW / [dpMg basicW];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
    
    // 添加时间
    CGFloat X = [dpMg marginW];
    NSString *dateStr = [[dpMg dateFormat] stringFromDate:[NSDate date]];
    ZHDPListColItem *colItem = [self createColItem:dateStr percent:datePercent X:X colorType:colorType];
    [colItems addObject:colItem];
    X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
    
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        colItem = [self createColItem:detail percent:otherPercent X:X colorType:colorType];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
        
        [titles addObject:[NSString stringWithFormat:@"%@参数%ld: \n", (i == 0 ? @"" : @"\n"), i]];
        [descs addObject:detail?:@""];
    }
    
    // 弹窗详情数据
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"参数";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
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
        [str appendString:dateStr];
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    // 添加数据
    [self addSecItemToList:ZHDPListLog.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListLog.class appItem:appItem secItem:secItem colorType:colorType];
}

- (void)zh_test_addNetwork:(NSDate *)startDate request:(NSURLRequest *)request response:(NSURLResponse *)response responseData:(NSData *)responseData{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_addNetworkSafe:startDate request:request response:response responseData:responseData];
    });
}
- (void)zh_test_addNetworkSafe:(NSDate *)startDate request:(NSURLRequest *)request response:(NSURLResponse *)response responseData:(NSData *)responseData{
    
    ZHDPManager *dpMg = ZHDPMg();
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    
    NSHTTPURLResponse *httpResponse = nil;
    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
        httpResponse = (NSHTTPURLResponse*)response;
    }
    
    NSURL *url = request.URL;
    NSDictionary *headers = request.allHTTPHeaderFields;
    NSDictionary *responseHeaders = httpResponse.allHeaderFields;
    NSDictionary *paramsInBody = [self parseDataFromRequestBody:request.HTTPBody];
    NSDictionary *paramsInBodyStream = [self parseDataFromRequestBody:[[dpMg fetchNetworkTask] convertToDataByInputStream:request.HTTPBodyStream]];
    NSString *urlStr = url.absoluteString;
    NSString *host = [request valueForHTTPHeaderField:@"host"];
    if (host) {
        urlStr = [urlStr stringByReplacingOccurrencesOfString:request.URL.host withString:host];
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
    
    NSString *method = request.HTTPMethod;
    NSString *statusCode = [NSString stringWithFormat:@"%ld",(NSInteger)httpResponse.statusCode];
    ZHDPOutputType colorType = ((statusCode.integerValue < 200 || statusCode.integerValue >= 300) ? ZHDPOutputType_Error :  ZHDPOutputType_Log);

    NSDate *endDate = [NSDate date];
    NSTimeInterval startTimeDouble = [startDate timeIntervalSince1970];
    NSTimeInterval endTimeDouble = [endDate timeIntervalSince1970];
    NSTimeInterval durationDouble = fabs(endTimeDouble - startTimeDouble);
//    model.startTime = [NSString stringWithFormat:@"%f", startTimeDouble];
//    model.endTime = [NSString stringWithFormat:@"%f", endTimeDouble];
    
    NSString *duration = [NSString stringWithFormat:@"%.3fms", durationDouble * 1000];
    NSString *appId = nil;
    NSString *appEnv = nil;
    NSString *appPath = nil;
    
    NSString *referer = [request valueForHTTPHeaderField:@"Referer"];
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
    CGFloat freeW = [dpMg basicW] - ([dpMg marginW] * (count + 1));
    NSArray *otherPercents = @[@(0.80 * freeW / [dpMg basicW]), @(0.10 * freeW / [dpMg basicW]), @(0.10 * freeW / [dpMg basicW])];

    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    
    CGFloat X = [dpMg marginW];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSNumber *percent = otherPercents[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        ZHDPListColItem *colItem = [self createColItem:detail percent:percent.floatValue X:X colorType:colorType];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
    }

    // 弹窗详情数据
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    NSArray *titles = @[@"URL: ", @"\nMethod: ", @"\nStatus Code: ", @"\nStart Time: ", @"\nEnd Time: ", @"\nDuration: "];
    NSArray *descs = @[urlStr?:@"",
                       method?:@"",
                       statusCode?:@"",
                       [[dpMg dateByFormat:@"yyyy-MM-dd HH:mm:ss.SSS"] stringFromDate:startDate]?:@"",
                       [[dpMg dateByFormat:@"yyyy-MM-dd HH:mm:ss.SSS"] stringFromDate:endDate]?:@"",
                       duration?:@""];
    
    item.title = @"概要";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    titles = @[@"Request Query (In URL): \n", @"\nRequest Query (In Body): \n", @"\nRequest Query (In BodyStream): \n"];
    descs = @[
        (^NSString *(){
            if (paramsInUrl.allKeys.count == 0) {
                return @"";
            }
            return [self jsonToString:paramsInUrl]?:@"";
        })(),
        (^NSString *(){
            __block NSString *res = nil;
            [self convertToString:paramsInBody block:^(NSString *conciseStr, NSString *detailStr) {
                res = detailStr;
            }];
            return res?:@"";
        })(),
        (^NSString *(){
            __block NSString *res = nil;
            [self convertToString:paramsInBodyStream block:^(NSString *conciseStr, NSString *detailStr) {
                res = detailStr;
            }];
            return res?:@"";
        })()];
    item.title = @"参数";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    titles = @[@"Response Data: \n"];
    descs = @[
        (^NSString *(){
            id obj = [self parseObjFromData:responseData]?:@"";
            __block NSString *res = nil;
            [self convertToString:obj block:^(NSString *conciseStr, NSString *detailStr) {
                res = detailStr;
            }];
            return res?:@"";
        })()
       ];
    item.title = @"数据";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    titles = @[@"Request Headers: \n"];
    descs = @[
        [self jsonToString:headers?:@{}]?:@""
       ];
    item.title = @"请求头";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    titles = @[@"Response Headers: \n"];
    descs = @[
        [self jsonToString:responseHeaders?:@{}]?:@"",
       ];
    item.title = @"响应头";
    item.content = [dpMg createDetailAttStr:titles descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    item.title = @"小程序";
    titles = @[@"小程序信息: \n"].mutableCopy;
        
    descs = @[[self jsonToString:@{@"appName": appItem.appName?:@"", @"appId": appItem.appId?:@"", @"path": appPath?:@""}]?:@""].mutableCopy;
    item.content = [dpMg createDetailAttStr:titles descs:descs];
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
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n\n%@:\n%@", item.title, item.content.string];
        }
        return str;
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
    CGFloat freeW = [dpMg basicW] - ([dpMg marginW] * (count + 1));
    NSArray *otherPercents = @[@(0.3 * freeW / [dpMg basicW]), @(0.7 * freeW / [dpMg basicW])];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
        
    CGFloat X = [dpMg marginW];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSNumber *percent = otherPercents[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        ZHDPListColItem *colItem = [self createColItem:detail percent:percent.floatValue X:X colorType:ZHDPOutputType_Log];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
        
        if (detail) [descs addObject:detail];
    }
    
    // 弹窗详情数据
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"数据";
    NSArray *titles = @[@"Key: \n", @"\nValue: \n"];
    item.content = [dpMg createDetailAttStr:titles descs:descs];
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
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    // 添加数据
    [self addSecItemToList:ZHDPListStorage.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListStorage.class appItem:appItem secItem:secItem colorType:ZHDPOutputType_Log];
}
- (void)fw_test_deleteStorageStore:(NSArray <ZHDPListSecItem *> *)secItems{
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
- (void)fw_test_deleteStorageStoreByData:(NSArray *)secItemsData{
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

- (void)zh_test_reloadMemory{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        [self zh_test_reloadMemorySafe];
    });
}
- (void)zh_test_reloadMemorySafe{
    ZHDPManager *dpMg = ZHDPMg();
    
    // 从全局数据管理中移除所有Memory数据
    NSArray <ZHDPAppDataItem *> *appDataItems = [dpMg.dataTask fetchAllAppDataItems];
    for (ZHDPAppDataItem *appDataItem in appDataItems) {
        [dpMg.dataTask cleanAllItems:appDataItem.memoryItems];
    }
    // 载入新数据
    [self zh_test_addMemorySafe];
    
}
- (void)zh_test_addMemorySafe{
    ZHDPManager *dpMg = ZHDPMg();
    
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    /*
     获取到的memory
     {
         key: {
             source: {
                 appId: xxx
             }
             data: data
         }
     }
     */
    NSDictionary *memory = @{@"abc": @{@"data": @"数据", @"source": @{@"appId": @"App"}}};
    if (!memory || ![memory isKindOfClass:NSDictionary.class] || memory.allKeys.count == 0) {
        return;
    }
    [memory enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *map, BOOL * stop1) {
        id data = [map objectForKey:@"data"];
        NSString *appId = [[map objectForKey:@"source"] objectForKey:@"appId"];
        [self zh_test_addMemorySafeSingle:appId args:@[key, data?:@""]];
    }];
}
- (void)zh_test_addMemorySafeSingle:(NSString *)appId args:(NSArray *)args{
    ZHDPManager *dpMg = ZHDPMg();
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = appId ?: @"App";
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
    CGFloat freeW = [dpMg basicW] - ([dpMg marginW] * (count + 1));
    NSArray *otherPercents = @[@(0.3 * freeW / [dpMg basicW]), @(0.7 * freeW / [dpMg basicW])];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
        
    CGFloat X = [dpMg marginW];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        NSNumber *percent = otherPercents[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        ZHDPListColItem *colItem = [self createColItem:detail percent:percent.floatValue X:X colorType:ZHDPOutputType_Log];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
        
        if (detail) [descs addObject:detail];
    }
    
    // 弹窗详情数据
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"数据";
    NSArray *titles = @[@"Key: \n", @"\nValue: \n"];
    item.content = [dpMg createDetailAttStr:titles descs:descs];
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
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    // 添加数据
    [self addSecItemToList:ZHDPListMemory.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListMemory.class appItem:appItem secItem:secItem colorType:ZHDPOutputType_Log];
}
- (void)fw_test_deleteMemoryStore:(NSArray <ZHDPListSecItem *> *)secItems{
    for (ZHDPListSecItem *secItem in secItems) {
        @autoreleasepool {
            if (secItem.rowItems.count == 0 ||  secItem.rowItems.firstObject.colItems.count == 0) {
                continue;
            }
            NSString *key =  secItem.rowItems.firstObject.colItems.firstObject.attTitle.string;
//            [[ZHMemoryManager shareManager] removeMemorySync:@{@"key": key?:@""} appId:nil extraInfo:nil];
        }
    }
}
- (void)fw_test_deleteMemoryStoreByData:(NSArray *)secItemsData{
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
//            [[ZHMemoryManager shareManager] removeMemorySync:@{@"key": key?:@""} appId:nil extraInfo:nil];
        }
    }
}

- (void)zh_test_addException:(NSString *)title stack:(NSString *)stack{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ZHDPMg().status != ZHDPManagerStatus_Open) {
            return;
        }
        if (!title || ![title isKindOfClass:NSString.class] || title.length == 0) {
            return;
        }
        ZHDPOutputType type = ZHDPOutputType_Error;
        [self zh_test_addExceptionSafe:@"App" colorType:type args:@[title] stack:stack];
    });
}
- (void)zh_test_addExceptionSafe:(NSString *)appId colorType:(ZHDPOutputType)colorType args:(NSArray *)args stack:(NSString *)stack{
    ZHDPManager *dpMg = ZHDPMg();
    
    if (dpMg.status != ZHDPManagerStatus_Open) {
        return;
    }
    
    if (!args || args.count <= 0) {
        return;
    }
    
    // 哪个应用的数据
    ZHDPAppItem *appItem = [[ZHDPAppItem alloc] init];
    appItem.appId = appId ?: @"App";
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
    CGFloat freeW = ([dpMg basicW] - ([dpMg marginW] * (count + 1 + 1)) - [dpMg dateW]) * 1.0 / (count * 1.0);
    CGFloat otherPercent = freeW / [dpMg basicW];
    
    // 每一行中的各个分段数据
    NSMutableArray <ZHDPListColItem *> *colItems = [NSMutableArray array];
    NSMutableArray <ZHDPListDetailItem *> *detailItems = [NSMutableArray array];
    NSMutableArray *descs = [NSMutableArray array];
    
    // 添加时间
    CGFloat X = [dpMg marginW];
    NSString *dateStr = [[dpMg dateFormat] stringFromDate:[NSDate date]];
    ZHDPListColItem *colItem = [self createColItem:dateStr percent:datePercent X:X colorType:colorType];
    [colItems addObject:colItem];
    X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
    
    for (NSUInteger i = 0; i < count; i++) {
        NSString *title = args[i];
        
        __block NSString *concise = nil;
        __block NSString *detail = nil;
        [dpMg convertToString:title block:^(NSString *conciseStr, NSString *detailStr) {
            concise = conciseStr;
            detail = detailStr;
        }];
        // 添加参数
        colItem = [self createColItem:detail percent:otherPercent X:X colorType:colorType];
        [colItems addObject:colItem];
        X += (colItem.rectValue.CGRectValue.size.width + [dpMg marginW]);
        
        [descs addObject:detail?:@""];
    }
    
    // 弹窗详情数据
    ZHDPListDetailItem *item = [[ZHDPListDetailItem alloc] init];
    item.title = @"简要";
    item.content = [dpMg createDetailAttStr:@[@"message: \n"] descs:descs];
    [detailItems addObject:item];
    
    item = [[ZHDPListDetailItem alloc] init];
    item.title = @"调用栈";
    item.content = [dpMg createDetailAttStr:@[@"stacktrace: \n"] descs:@[stack?:@""]];
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
        [str appendString:dateStr];
        for (ZHDPListDetailItem *item in detailItems) {
            [str appendFormat:@"\n\n%@:\n%@", item.title, item.content.string];
        }
        return str;
    };
    
    // 添加数据
    [self addSecItemToList:ZHDPListException.class appItem:appItem secItem:secItem];
    // 发送socket
    [self sendSocketClientSecItemToList:ZHDPListException.class appItem:appItem secItem:secItem colorType:colorType];
}
@end

