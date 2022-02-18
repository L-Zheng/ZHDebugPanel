//
//  ZHDPStorageManager.h
//  ZHDebugPanel
//
//  Created by EM on 2022/2/18.
//

#import <Foundation/Foundation.h>

@interface ZHDPStorageManager : NSObject
+ (instancetype)shareManager;

- (void)updateConfig_max:(NSString *)key count:(NSUInteger)count;
- (NSNumber *)fetchConfig_max:(NSString *)key;

@end

__attribute__((unused)) static ZHDPStorageManager * ZHDPStorageMg() {
    return [ZHDPStorageManager shareManager];
}
