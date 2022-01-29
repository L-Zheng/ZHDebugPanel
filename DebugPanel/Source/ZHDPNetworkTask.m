//
//  ZHDPNetworkTask.m
//  ZHJSNative
//
//  Created by EM on 2021/6/3.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import "ZHDPNetworkTask.h"
#import "ZHDPManager.h"// 调试面板管理
#import <objc/runtime.h>
/*截获系统请求
 
 NSURLSession.NSURLSessionConfiguration.protocolClasses
 系统会按照protocolClasses数组下的class  依次进行决议
 ProtocolB  + (BOOL)canInitWithRequest:
 ProtocolA  + (BOOL)canInitWithRequest:

 ProtocolB   ProtocolA
 return NO   return NO   交由系统处理
 return NO   return YES
                         依次调用
                         ProtocolA->
                         startLoading->
                         canInitWithRequest->
                         if ([NSURLProtocol propertyForKey:@"xx" inRequest:request] ) {
                             return NO;
                         }->
                         ProtocolB->
                         canInitWithRequest->
                         // 如果此时返回YES  会交给ProtocolB处理 造成混乱 请求可能丢弃
                         if ([NSURLProtocol propertyForKey:@"xxx" inRequest:request] ) {
                             return NO;
                         }->
 return YES   return NO
                         依次调用
                         ProtocolB->
                         startLoading->
                         canInitWithRequest->
                         if ([NSURLProtocol propertyForKey:@"xx" inRequest:request] ) {
                             return NO;
                         }->
                         ProtocolA->
                         canInitWithRequest->
                         // 如果此时返回YES  会交给ProtocolA处理 造成混乱 请求可能丢弃
                         if ([NSURLProtocol propertyForKey:@"xxx" inRequest:request] ) {
                             return NO;
                         }->
 return YES   return YES  同上
 */

typedef NSURLSessionConfiguration *(*ZHDPSessionConfigConstructor)(id,SEL);

static ZHDPSessionConfigConstructor zhdp_orig_defaultSessionConfiguration;
static ZHDPSessionConfigConstructor zhdp_orig_ephemeralSessionConfiguration;

static NSURLSessionConfiguration * zhdp_addSessionConfiguration(NSURLSessionConfiguration *config){
    if ([config respondsToSelector:@selector(protocolClasses)] && [config respondsToSelector:@selector(setProtocolClasses:)]) {
        NSMutableArray *urlProtocolClasses = [NSMutableArray arrayWithArray:config.protocolClasses];
        Class protoCls = ZHDPNetworkTaskProtocol.class;
        if (![urlProtocolClasses containsObject:protoCls]) {
            [urlProtocolClasses insertObject:protoCls atIndex:0];
        }
        config.protocolClasses = urlProtocolClasses;
    }
    return config;
}
static NSURLSessionConfiguration * zhdp_replaced_defaultSessionConfiguration(id self, SEL _cmd){
    NSURLSessionConfiguration *config = zhdp_orig_defaultSessionConfiguration(self,_cmd);
    return zhdp_addSessionConfiguration(config);
}
static NSURLSessionConfiguration * zhdp_replaced_ephemeralSessionConfiguration(id self, SEL _cmd){
    NSURLSessionConfiguration *config = zhdp_orig_ephemeralSessionConfiguration(self,_cmd);
    return zhdp_addSessionConfiguration(config);
}
IMP zhdp_replaceMethod(SEL selector, IMP newImpl, Class affectedClass, BOOL isClassMethod){
    Method origMethod = isClassMethod ? class_getClassMethod(affectedClass, selector) : class_getInstanceMethod(affectedClass, selector);
    IMP origImpl = method_getImplementation(origMethod);

    if (!class_addMethod(isClassMethod ? object_getClass(affectedClass) : affectedClass, selector, newImpl, method_getTypeEncoding(origMethod))){
        method_setImplementation(origMethod, newImpl);
    }
    return origImpl;
}
extern NSURLCacheStoragePolicy zhdp_cacheStoragePolicyForRequestAndResponse(NSURLRequest * request, NSHTTPURLResponse * response){
    BOOL                        cacheable;
    NSURLCacheStoragePolicy     result;

    // First determine if the request is cacheable based on its status code.
    
    switch ([response statusCode]) {
        case 200:
        case 203:
        case 206:
        case 301:
        case 304:
        case 404:
        case 410: {
            cacheable = YES;
        } break;
        default: {
            cacheable = NO;
        } break;
    }

    // If the response might be cacheable, look at the "Cache-Control" header in
    // the response.

    // IMPORTANT: We can't rely on -rangeOfString: returning valid results if the target
    // string is nil, so we have to explicitly test for nil in the following two cases.
    
    if (cacheable) {
        NSString *  responseHeader;
        
        responseHeader = [[response allHeaderFields][@"Cache-Control"] lowercaseString];
        if ( (responseHeader != nil) && [responseHeader rangeOfString:@"no-store"].location != NSNotFound) {
            cacheable = NO;
        }
    }

    // If we still think it might be cacheable, look at the "Cache-Control" header in
    // the request.

    if (cacheable) {
        NSString *  requestHeader;

        requestHeader = [[request allHTTPHeaderFields][@"Cache-Control"] lowercaseString];
        if ( (requestHeader != nil)
          && ([requestHeader rangeOfString:@"no-store"].location != NSNotFound)
          && ([requestHeader rangeOfString:@"no-cache"].location != NSNotFound) ) {
            cacheable = NO;
        }
    }

    // Use the cacheable flag to determine the result.
    
    if (cacheable) {
    
        // This code only caches HTTPS data in memory.  This is inline with earlier versions of
        // iOS.  Modern versions of iOS use file protection to protect the cache, and thus are
        // happy to cache HTTPS on disk.  I've not made the correspondencing change because
        // it's nice to see all three cache policies in action.
    
        if ([[[[request URL] scheme] lowercaseString] isEqual:@"https"]) {
            result = NSURLCacheStorageAllowedInMemoryOnly;
        } else {
            result = NSURLCacheStorageAllowed;
        }
    } else {
        result = NSURLCacheStorageNotAllowed;
    }

    return result;
}

// 拦截其它库的请求   可能存在其它库已经拦截了app的请求   自身库如果拦截   存在多处拦截  容易出问题
static BOOL ZHDPNetworkTask_CaptureOtherLib = NO;

#pragma mark - network

static void (* zhdp_ori_startLoading) (id, SEL);
static void zhdp_new_startLoading(id self, SEL _cmd){
    if (zhdp_ori_startLoading) {
        zhdp_ori_startLoading(self, _cmd);
    }
    if (![ZHDPMg() fetchNetworkTask].interceptEnable) return;
    
    NSString *key = [NSString stringWithFormat:@"%p", self];
    
    ZHDPNetworkTaskProtocol *networkP = [[ZHDPNetworkTaskProtocol alloc] init];
    [networkP collect_startLoading:self];
    [[ZHDPMg() fetchNetworkTask] addURLProtocol:networkP key:key];
}
static void (* zhdp_ori_stopLoading) (id, SEL);
static void zhdp_new_stopLoading(id self, SEL _cmd){
    if (zhdp_ori_stopLoading) {
        zhdp_ori_stopLoading(self, _cmd);
    }
    if (![ZHDPMg() fetchNetworkTask].interceptEnable) return;
    
    NSString *key = [NSString stringWithFormat:@"%p", self];
    
    NSURLProtocol *networkP = [[ZHDPMg() fetchNetworkTask] fetchURLProtocolForKey:key];
    if (![networkP isKindOfClass:ZHDPNetworkTaskProtocol.class]) return;
    
    [(ZHDPNetworkTaskProtocol *)networkP collect_stopLoading:self];
}
static void (* zhdp_ori_URLSession_task_didCompleteWithError) (id, SEL, NSURLSession *, NSURLSessionTask *, NSError *);
static void zhdp_new_URLSession_task_didCompleteWithError(id self, SEL _cmd, NSURLSession *session, NSURLSessionTask *task, NSError *error){
    if (zhdp_ori_URLSession_task_didCompleteWithError) {
        zhdp_ori_URLSession_task_didCompleteWithError(self, _cmd, session, task, error);
    }
    if (![ZHDPMg() fetchNetworkTask].interceptEnable) return;
    
    NSString *key = [NSString stringWithFormat:@"%p", self];
    
    NSURLProtocol *networkP = [[ZHDPMg() fetchNetworkTask] fetchURLProtocolForKey:key];
    if (![networkP isKindOfClass:ZHDPNetworkTaskProtocol.class]) return;
    
    [[ZHDPMg() fetchNetworkTask] removeURLProtocolForKey:key];
    [(ZHDPNetworkTaskProtocol *)networkP collect_URLSession:session task:task didCompleteWithError:error];
}
static void (* zhdp_ori_URLSession_dataTask_didReceiveResponse) (id, SEL, NSURLSession *, NSURLSessionDataTask *, NSURLResponse *, void (^)(NSURLSessionResponseDisposition));
static void zhdp_new_URLSession_dataTask_didReceiveResponse(id self, SEL _cmd, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void (^completionHandler)(NSURLSessionResponseDisposition)){
    if (zhdp_ori_URLSession_dataTask_didReceiveResponse) {
        zhdp_ori_URLSession_dataTask_didReceiveResponse(self, _cmd, session, dataTask, response, completionHandler);
    }
    if (![ZHDPMg() fetchNetworkTask].interceptEnable) return;
    
    NSString *key = [NSString stringWithFormat:@"%p", self];
    
    NSURLProtocol *networkP = [[ZHDPMg() fetchNetworkTask] fetchURLProtocolForKey:key];
    if (![networkP isKindOfClass:ZHDPNetworkTaskProtocol.class]) return;
    
    [(ZHDPNetworkTaskProtocol *)networkP collect_URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}
static void (* zhdp_ori_URLSession_dataTask_didReceiveData) (id, SEL, NSURLSession *, NSURLSessionDataTask *, NSData *);
static void zhdp_new_URLSession_dataTask_didReceiveData(id self, SEL _cmd, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data){
    if (zhdp_ori_URLSession_dataTask_didReceiveData) {
        zhdp_ori_URLSession_dataTask_didReceiveData(self, _cmd, session, dataTask, data);
    }
    if (![ZHDPMg() fetchNetworkTask].interceptEnable) return;
    
    NSString *key = [NSString stringWithFormat:@"%p", self];
    
    NSURLProtocol *networkP = [[ZHDPMg() fetchNetworkTask] fetchURLProtocolForKey:key];
    if (![networkP isKindOfClass:ZHDPNetworkTaskProtocol.class]) return;
    
    [(ZHDPNetworkTaskProtocol *)networkP collect_URLSession:session dataTask:dataTask didReceiveData:data];
}
static void (* zhdp_ori_URLSession_task_willPerformHTTPRedirection_newRequest) (id, SEL, NSURLSession *, NSURLSessionTask *, NSHTTPURLResponse *, NSURLRequest *, void (^)(NSURLRequest *));
static void zhdp_new_URLSession_task_willPerformHTTPRedirection_newRequest(id self, SEL _cmd, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *request, void (^completionHandler)(NSURLRequest *)){
    if (zhdp_ori_URLSession_task_willPerformHTTPRedirection_newRequest) {
        zhdp_ori_URLSession_task_willPerformHTTPRedirection_newRequest(self, _cmd, session, task, response, request, completionHandler);
    }
    if (![ZHDPMg() fetchNetworkTask].interceptEnable) return;
    
    NSString *key = [NSString stringWithFormat:@"%p", self];
    
    NSURLProtocol *networkP = [[ZHDPMg() fetchNetworkTask] fetchURLProtocolForKey:key];
    if (![networkP isKindOfClass:ZHDPNetworkTaskProtocol.class]) return;
    
    [(ZHDPNetworkTaskProtocol *)networkP collect_URLSession:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
}

#pragma mark - controller dealloc

static void (* zhdp_ori_dismissViewControllerAnimated_completion) (id, SEL, BOOL, void (^)(void));
static void zhdp_new_dismissViewControllerAnimated_completion(id self, SEL _cmd, BOOL flag, void (^completion)(void)){
    [ZHDPMg() addDealloc_controller_dismiss:self];
    if (zhdp_ori_dismissViewControllerAnimated_completion) {
        zhdp_ori_dismissViewControllerAnimated_completion(self, _cmd, flag, completion);
    }
}
static UIViewController * (* zhdp_ori_navi_popViewControllerAnimated) (id, SEL, BOOL);
static UIViewController * zhdp_new_navi_popViewControllerAnimated(id self, SEL _cmd, BOOL animated){
    UIViewController *res = nil;
    if (zhdp_ori_navi_popViewControllerAnimated) {
        res = zhdp_ori_navi_popViewControllerAnimated(self, _cmd, animated);
        if (res) {
            [ZHDPMg() addDealloc_controller_navi_pop:self popCtrls:@[res]];
        }
    }
    return res;
}
static NSArray<__kindof UIViewController *> * (* zhdp_ori_navi_popToViewController_animated) (id, SEL, UIViewController *, BOOL);
static NSArray<__kindof UIViewController *> * zhdp_new_navi_popToViewController_animated(id self, SEL _cmd, UIViewController *viewController, BOOL animated){
    NSArray<__kindof UIViewController *> *res = nil;
    if (zhdp_ori_navi_popToViewController_animated) {
        res = zhdp_ori_navi_popToViewController_animated(self, _cmd, viewController, animated);
        [ZHDPMg() addDealloc_controller_navi_pop:self popCtrls:res];
    }
    return res;
}
static NSArray<__kindof UIViewController *> * (* zhdp_ori_navi_popToRootViewControllerAnimated) (id, SEL, BOOL);
static NSArray<__kindof UIViewController *> * zhdp_new_navi_popToRootViewControllerAnimated(id self, SEL _cmd, BOOL animated){
    NSArray<__kindof UIViewController *> *res = nil;
    if (zhdp_ori_navi_popToRootViewControllerAnimated) {
        res = zhdp_ori_navi_popToRootViewControllerAnimated(self, _cmd, animated);
        [ZHDPMg() addDealloc_controller_navi_pop:self popCtrls:res];
    }
    return res;
}
/*UINavigationController
 调用setViewControllers:方法 会触发 setViewControllers:animated:  不会触发pop相关方法
 调用
    popViewControllerAnimated:
    popToViewController:animated
    popToRootViewControllerAnimated:
 不会触发 setViewControllers:方法
 */
static void (* zhdp_ori_navi_setViewControllers_animated) (id, SEL, NSArray<__kindof UIViewController *> *, BOOL);
static void zhdp_new_navi_setViewControllers_animated(id self, SEL _cmd, NSArray<__kindof UIViewController *> *viewControllers, BOOL animated){
    if (zhdp_ori_navi_setViewControllers_animated) {
        NSArray *oriCtrls = nil;
        if (ZHDPMg().status == ZHDPManagerStatus_Open) {
            if ([self isKindOfClass:UINavigationController.class]) {
                oriCtrls = [(UINavigationController *)self viewControllers];
            }
        }
        zhdp_ori_navi_setViewControllers_animated(self, _cmd, viewControllers, animated);
        if (oriCtrls && oriCtrls.count > 0) {
            [ZHDPMg() addDealloc_controller_navi_setCtrls:self oriCtrls:oriCtrls newCtrls:viewControllers];
        }
    }
}

#pragma mark - NetworkTaskProtocol

@interface ZHDPNetworkTaskProtocol ()<NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate>
@property (atomic, strong) NSURLConnection  *connection;
@property (atomic, strong) NSURLResponse    *response;
@property (atomic, strong) NSMutableData    *data;
@property (atomic, strong) NSDate   *startDate;

@property (nonnull,strong) NSURLSessionDataTask *task;


@property (nonatomic,strong) NSURL *url_temp;
@property (nonatomic,strong) NSDictionary *headers_temp;
@property (nonatomic,strong) NSData *httpBody_temp;
@property (nonatomic,strong) NSInputStream *httpBodyStream_temp;
@property (nonatomic,copy) NSString *requestMethod_temp;
@end

@implementation ZHDPNetworkTaskProtocol
+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // 捕获controller
        Class cls = [UIViewController class];
        zhdp_ori_dismissViewControllerAnimated_completion = (void (*) (id, SEL, BOOL, void (^)(void)))
        zhdp_replaceMethod(
                           @selector(dismissViewControllerAnimated:completion:),
                           (IMP)zhdp_new_dismissViewControllerAnimated_completion,
                           cls,
                           NO);
        
        // 捕获navicontroller
        cls = [UINavigationController class];
        zhdp_ori_navi_popViewControllerAnimated = (UIViewController * (*) (id, SEL, BOOL))
        zhdp_replaceMethod(
                           @selector(popViewControllerAnimated:),
                           (IMP)zhdp_new_navi_popViewControllerAnimated,
                           cls,
                           NO);
        zhdp_ori_navi_popToViewController_animated = (NSArray<__kindof UIViewController *> * (*) (id, SEL, UIViewController *, BOOL))
        zhdp_replaceMethod(
                           @selector(popToViewController:animated:),
                           (IMP)zhdp_new_navi_popToViewController_animated,
                           cls,
                           NO);
        zhdp_ori_navi_popToRootViewControllerAnimated = (NSArray<__kindof UIViewController *> * (*) (id, SEL, BOOL))
        zhdp_replaceMethod(
                           @selector(popToRootViewControllerAnimated:),
                           (IMP)zhdp_new_navi_popToRootViewControllerAnimated,
                           cls,
                           NO);
        zhdp_ori_navi_setViewControllers_animated = (void (*) (id, SEL, NSArray<__kindof UIViewController *> *, BOOL))
        zhdp_replaceMethod(
                           @selector(setViewControllers:animated:),
                           (IMP)zhdp_new_navi_setViewControllers_animated,
                           cls,
                           NO);
        
        // 捕获network
        cls = NSClassFromString(@"XXXURLProtocol");
        ZHDPNetworkTask_CaptureOtherLib = (cls ? YES : NO);
        if (!ZHDPNetworkTask_CaptureOtherLib) {
            zhdp_orig_defaultSessionConfiguration = (ZHDPSessionConfigConstructor)
            zhdp_replaceMethod(
                               @selector(defaultSessionConfiguration),
                               (IMP)zhdp_replaced_defaultSessionConfiguration,
                               [NSURLSessionConfiguration class],
                               YES);
            
            zhdp_orig_ephemeralSessionConfiguration = (ZHDPSessionConfigConstructor)
            zhdp_replaceMethod(
                               @selector(ephemeralSessionConfiguration),
                               (IMP)zhdp_replaced_ephemeralSessionConfiguration,
                               [NSURLSessionConfiguration class],
                               YES);
        }else{
            zhdp_ori_startLoading = (void (*) (id, SEL))
            zhdp_replaceMethod(
                               @selector(startLoading),
                               (IMP)zhdp_new_startLoading,
                               cls,
                               NO);
            
            zhdp_ori_stopLoading = (void (*) (id, SEL))
            zhdp_replaceMethod(
                               @selector(stopLoading),
                               (IMP)zhdp_new_stopLoading,
                               cls,
                               NO);
            
            zhdp_ori_URLSession_task_didCompleteWithError = (void (*) (id, SEL, NSURLSession *, NSURLSessionTask *, NSError *))
            zhdp_replaceMethod(
                               @selector(URLSession:task:didCompleteWithError:),
                               (IMP)zhdp_new_URLSession_task_didCompleteWithError,
                               cls,
                               NO);
            
            zhdp_ori_URLSession_dataTask_didReceiveResponse = (void (*) (id, SEL, NSURLSession *, NSURLSessionDataTask *, NSURLResponse *, void (^)(NSURLSessionResponseDisposition)))
            zhdp_replaceMethod(
                               @selector(URLSession:dataTask:didReceiveResponse:completionHandler:),
                               (IMP)zhdp_new_URLSession_dataTask_didReceiveResponse,
                               cls,
                               NO);
            
            zhdp_ori_URLSession_dataTask_didReceiveData = (void (*) (id, SEL, NSURLSession *, NSURLSessionDataTask *, NSData *))
            zhdp_replaceMethod(
                               @selector(URLSession:dataTask:didReceiveData:),
                               (IMP)zhdp_new_URLSession_dataTask_didReceiveData,
                               cls,
                               NO);
            
            zhdp_ori_URLSession_task_willPerformHTTPRedirection_newRequest = (void (*) (id, SEL, NSURLSession *, NSURLSessionTask *, NSHTTPURLResponse *, NSURLRequest *, void (^)(NSURLRequest *)))
            zhdp_replaceMethod(
                               @selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:),
                               (IMP)zhdp_new_URLSession_task_willPerformHTTPRedirection_newRequest,
                               cls,
                               NO);
        }
    });
}
+ (NSString *)URLProperty{
    return NSStringFromClass(self);
}
+ (BOOL)canInitWithRequest:(NSURLRequest *)request{
    // return YES:拦截   return NO:不拦截
    
    if (ZHDPNetworkTask_CaptureOtherLib) {
        return NO;
    }
    if (![ZHDPMg() fetchNetworkTask].interceptEnable) {
        return NO;
    }
    
    // 只处理http请求
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    // 防止重复请求
    if ([NSURLProtocol propertyForKey:[self URLProperty] inRequest:request] ) {
        return NO;
    }
    // 只截获的url
    NSArray <NSString *> *onlyURLs = @[];
    if (onlyURLs.count > 0) {
        NSString *url = [request.URL.absoluteString lowercaseString];
        for (NSString *tUrl in onlyURLs) {
            if ([url rangeOfString:[tUrl lowercaseString]].location != NSNotFound)
                return YES;
        }
        return NO;
    }
    
    // 默认全部截获
    return YES;
}
//返回规范的request
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:[self URLProperty] inRequest:mutableReqeust];
    return [mutableReqeust copy];
}
// 判断两个请求是否是同一个请求，如果是，则可以使用缓存数据，默认为YES
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b{
    return [super requestIsCacheEquivalent:a toRequest:b];
}
- (void)startLoading{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:[self.class URLProperty] inRequest:mutableReqeust];
    
    if ([self useURLSession]) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSArray *protocolClasses = configuration.protocolClasses ?: @[];
        NSMutableArray *protocolArray = protocolClasses.mutableCopy;
        Class utURLProtocolClass = ZHDPNetworkTaskProtocol.class;
        // 判断是否已经添加过
        NSInteger findIndex = NSNotFound;
        for (int i = 0; i < protocolClasses.count; i++) {
            Class pClass = protocolClasses[i];
            if (pClass == utURLProtocolClass) {
                findIndex = i; break;
            }
        }
        if (findIndex == NSNotFound) {
            [protocolArray insertObject:utURLProtocolClass atIndex:0];
        }else {
            [protocolArray exchangeObjectAtIndex:0 withObjectAtIndex:findIndex];
        }
        configuration.protocolClasses = protocolArray;
        // 可能存在 此函数在主线程调起  同步等待请求结果  若请求delegate也在主线程  可能造成死锁
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[ZHDPMg() fetchNetworkTask].networkQueue];
        self.task = [session dataTaskWithRequest:mutableReqeust];
        [self.task resume];
    }else{
   #pragma clang diagnostic push
   #pragma clang diagnostic ignored "-Wdeprecated-declarations"
       self.connection = [NSURLConnection connectionWithRequest:mutableReqeust delegate:self];
   #pragma clang diagnostic pop
    }
    
    [self collect_startLoading:self];
}
- (void)stopLoading{
    if ([self useURLSession]) {
        if (self.task != nil) {
            [self.task cancel];
        }
    }else{
       if (self.connection) {
           [self.connection cancel];
           self.connection = nil;
       }
    }
    
    [self collect_stopLoading:self];
}

#pragma mark - collect

- (void)collect_startLoading:(NSURLProtocol *)urlProtocol{
    self.data = [NSMutableData data];
    self.startDate = [NSDate date];
    // 提前获取request的数据 如果stopLoading里面获取 可能request已经释放 造成崩溃
    self.url_temp = urlProtocol.request.URL.copy;
    self.headers_temp = urlProtocol.request.allHTTPHeaderFields.copy;
    self.httpBody_temp = urlProtocol.request.HTTPBody.copy;
    // HTTPBodyStream尽量不要提前读取  会破坏  stream.streamStatus  状态  影响请求发起
    self.httpBodyStream_temp = urlProtocol.request.HTTPBodyStream;
    self.requestMethod_temp = urlProtocol.request.HTTPMethod.copy;
}
- (void)collect_stopLoading:(NSURLProtocol *)urlProtocol{
    if (![self useURLSession]) {
        // 在 didCompleteWithError  函数中收集
//        NSData *streamData = [[ZHDPMg() fetchNetworkTask] convertToDataByInputStream:self.httpBodyStream_temp].copy;
//        [ZHDPMg() zh_test_addNetwork:self.startDate url:self.url_temp method:self.requestMethod_temp headers:self.headers_temp httpBody:self.httpBody_temp httpBodyStream:streamData response:self.response responseData:[NSData dataWithData:self.data]];
//        self.data = nil;
        
        // 不可在此处访问request 可能request已经释放 造成崩溃
    //    [ZHDPMg() zh_test_addNetwork:self.startDate request:self.request response:self.response responseData:[NSData dataWithData:self.data]];
//        self.data = nil;
    }
}
- (void)collect_URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSData *streamData = [[ZHDPMg() fetchNetworkTask] convertToDataByInputStream:self.httpBodyStream_temp].copy;
    [ZHDPMg() zh_test_addNetwork:self.startDate url:self.url_temp method:self.requestMethod_temp headers:self.headers_temp httpBody:self.httpBody_temp httpBodyStream:streamData response:self.response responseData:[NSData dataWithData:self.data]];
    self.data = nil;
}
- (void)collect_URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    self.response = response;
}
- (void)collect_URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [self.data appendData:data];
}
- (void)collect_URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler{
}

#pragma mark - enable

- (BOOL)useURLSession{
    return YES;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    if (!error) {
        [[self client] URLProtocolDidFinishLoading:self];
    } else {
        [[self client] URLProtocol:self didFailWithError:error];
    }
    
    [self collect_URLSession:session task:task didCompleteWithError:error];
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    NSURLCacheStoragePolicy cacheStoragePolicy = NSURLCacheStorageNotAllowed;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        cacheStoragePolicy = zhdp_cacheStoragePolicyForRequestAndResponse(dataTask.originalRequest, (NSHTTPURLResponse *) response);
    }
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:cacheStoragePolicy];
    completionHandler(NSURLSessionResponseAllow);
    self.response = response;
    
    [self collect_URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [[self client] URLProtocol:self didLoadData:data];
    [self collect_URLSession:session dataTask:dataTask didReceiveData:data];
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                  willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler{
    if (completionHandler) {
        completionHandler(proposedResponse);
    }
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler{
    //重定向 状态码 >=300 && < 400
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger status = httpResponse.statusCode;
        if (status >= 300 && status < 400) {
            [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
            //记得设置成nil，要不然正常请求会请求两次
            request = nil;
        }
    }
    completionHandler(request);
    
    [self collect_URLSession:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (!error) {
        [[self client] URLProtocolDidFinishLoading:self];
    } else {
        [[self client] URLProtocol:self didFailWithError:error];
    }
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return YES;
}

//解決發送IP地址的HTTPS請求 證書驗證
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (!challenge) {
        return;
    }
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        //構造一個NSURLCredential發送給發起方
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    } else {
        //對於其他驗證方法直接進行處理流程
        [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

#pragma GCC diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[self client] URLProtocol:self didReceiveAuthenticationChallenge:challenge];
}
- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[self client] URLProtocol:self didCancelAuthenticationChallenge:challenge];
}
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    if ([[protectionSpace authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        return YES;
    }
    return NO;
}
#pragma GCC diagnostic pop



#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSURLCacheStoragePolicy cacheStoragePolicy = NSURLCacheStorageNotAllowed;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        cacheStoragePolicy = zhdp_cacheStoragePolicyForRequestAndResponse(connection.originalRequest, (NSHTTPURLResponse *) response);
    }
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:cacheStoragePolicy];
    self.response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
    [self.data appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
//    [[self client] URLProtocol:self cachedResponseIsValid:cachedResponse];
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    //重定向 状态码 >=300 && < 400
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger status = httpResponse.statusCode;
        if (status >= 300 && status < 400) {
            [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
            //记得设置成nil，要不然正常请求会请求两次
            request = nil;
        }
    }
    return request;
}

- (void)dealloc{
}
@end


@interface ZHDPNetworkTask ()
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSMutableDictionary *urlProtocolMap;
@end
@implementation ZHDPNetworkTask

- (instancetype)init{
    self = [super init];
    if (self) {
        NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
        opQueue.maxConcurrentOperationCount = 3;
        self.networkQueue = opQueue;
        
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)interceptNetwork{
    self.interceptEnable = YES;
    if (!ZHDPNetworkTask_CaptureOtherLib) {
        [NSURLProtocol registerClass:[ZHDPNetworkTaskProtocol class]];
    }
}
- (void)cancelNetwork{
    self.interceptEnable = NO;
    if (!ZHDPNetworkTask_CaptureOtherLib) {
        [NSURLProtocol unregisterClass:[ZHDPNetworkTaskProtocol class]];
    }
}

- (void)addURLProtocol:(NSURLProtocol *)urlProtocol key:(NSString *)key{
    if (!key || ![key isKindOfClass:NSString.class] || key.length == 0 ||
        ![urlProtocol isKindOfClass:NSURLProtocol.class]) {
        return;
    }
    [self.lock lock];
    
    if (!self.urlProtocolMap) {
        self.urlProtocolMap = [NSMutableDictionary dictionary];
    }
    [self.urlProtocolMap setObject:urlProtocol forKey:key];
    
    [self.lock unlock];
}
- (void)removeURLProtocolForKey:(NSString *)key{
    if (!key || ![key isKindOfClass:NSString.class] || key.length == 0) {
        return;
    }
    [self.lock lock];
    [self.urlProtocolMap removeObjectForKey:key];
    [self.lock unlock];
}
- (NSURLProtocol *)fetchURLProtocolForKey:(NSString *)key{
    if (!key || ![key isKindOfClass:NSString.class] || key.length == 0) {
        return nil;
    }
    NSURLProtocol *res = nil;
    [self.lock lock];
    res = [self.urlProtocolMap objectForKey:key];
    [self.lock unlock];
    return res;
}

- (NSData *)convertToDataByInputStream:(NSInputStream *)stream{
    if (!stream || ![stream isKindOfClass:NSInputStream.class]) {
        return nil;
    }
    NSMutableData * data = [NSMutableData data];
    [stream open];
    NSInteger result;
    uint8_t buffer[1024]; // BUFFER_LEN can be any positive integer
    
    while((result = [stream read:buffer maxLength:1024]) != 0) {
        if(result > 0) {
            // buffer contains result bytes of data to be handled
            [data appendBytes:buffer length:result];
        } else {
            // The stream had an error. You can get an NSError object using [iStream streamError]
            if (result<0) {
                [stream close];
//                [NSException raise:@"STREAM_ERROR" format:@"%@", [stream streamError]];
                return nil;//liman
            }
        }
    }
    [stream close];
    return data;
}

@end


