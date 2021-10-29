//
//  ZHDPNetworkTask.h
//  ZHJSNative
//
//  Created by EM on 2021/6/3.
//  Copyright © 2021 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZHDPNetworkTaskProtocol : NSURLProtocol

#pragma mark - collect

- (void)collect_startLoading:(NSURLProtocol *)urlProtocol;
- (void)collect_stopLoading:(NSURLProtocol *)urlProtocol;
- (void)collect_URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;
- (void)collect_URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler;
- (void)collect_URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data;
- (void)collect_URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request  completionHandler:(void (^)(NSURLRequest *))completionHandler;

@end

@interface ZHDPNetworkTask : NSObject
@property (nonatomic,strong) NSOperationQueue *networkQueue;
@property (nonatomic, assign) BOOL interceptEnable;

- (void)interceptNetwork;
- (void)cancelNetwork;

- (void)addURLProtocol:(NSURLProtocol *)urlProtocol key:(NSString *)key;
- (void)removeURLProtocolForKey:(NSString *)key;
- (NSURLProtocol *)fetchURLProtocolForKey:(NSString *)key;

- (NSData *)convertToDataByInputStream:(NSInputStream *)stream;
@end
