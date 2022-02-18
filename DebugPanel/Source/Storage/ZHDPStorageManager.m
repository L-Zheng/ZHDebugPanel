//
//  ZHDPStorageManager.m
//  ZHDebugPanel
//
//  Created by EM on 2022/2/18.
//

#import "ZHDPStorageManager.h"

@interface ZHDPStorageManager ()
@property (nonatomic, strong) NSMutableDictionary *config;
@end

@implementation ZHDPStorageManager

- (NSString *)fetchStorageDir{
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[[userPaths firstObject] stringByAppendingPathComponent:@"com.zh.DebugPanel"] stringByAppendingPathComponent:@"DebugPanel"];
}
- (NSString *)fetchConfigFile{
    return [[self fetchStorageDir] stringByAppendingPathComponent:@"DebugPanel.json"];
}
- (NSMutableDictionary *)fetchConfig{
    if (self.config) {
        return self.config;
    }
    
    self.config = [NSMutableDictionary dictionary];
    
    NSString *file = [self fetchConfigFile];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL isDirectory = YES;
    if (![fm fileExistsAtPath:file isDirectory:&isDirectory] || isDirectory) {
        return self.config;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:file];
    if (!data) {
        return self.config;
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
        return self.config;
    }
    self.config = [json mutableCopy];
    return self.config;
}
- (void)updateConfig:(NSDictionary *)json{
    if (!json || ![json isKindOfClass:NSDictionary.class]) {
        return;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *folder = [self fetchStorageDir];
    NSString *file = [self fetchConfigFile];
    
    BOOL isDirectory = NO;
    if (![fm fileExistsAtPath:folder isDirectory:&isDirectory] || !isDirectory) {
        [fm removeItemAtPath:folder error:nil];
        [fm createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSError *jsonError = nil;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&jsonError];
        data = (jsonError ? nil : data);
    } @catch (NSException *exception) {
    } @finally {
    }
    if (data) {
        [data writeToFile:file atomically:YES];
        self.config = [json mutableCopy];
    }
}
- (void)updateConfig_max:(NSString *)key count:(NSUInteger)count{
    if (!key || ![key isKindOfClass:NSString.class] || key.length == 0) {
        return;
    }
    NSMutableDictionary *config = [self fetchConfig];
    NSMutableDictionary *max = [[config objectForKey:@"max"] mutableCopy];
    if (!max || ![max isKindOfClass:NSMutableDictionary.class]) {
        max = [NSMutableDictionary dictionary];
    }
    [max setObject:@(count) forKey:key];
    [config setObject:max forKey:@"max"];
    [self updateConfig:config];
}
- (NSNumber *)fetchConfig_max:(NSString *)key{
    if (!key || ![key isKindOfClass:NSString.class] || key.length == 0) {
        return nil;
    }
    NSDictionary *max = [[self fetchConfig] objectForKey:@"max"];
    return [max objectForKey:key];
}

#pragma mark - share

- (instancetype)init{
    if (self = [super init]) {
        // 只加载一次的资源
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
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
