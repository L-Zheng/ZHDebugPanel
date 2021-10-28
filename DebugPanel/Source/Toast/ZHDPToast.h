//
//  ZHDPToast.h
//  Pods-Demo
//
//  Created by EM on 2021/9/26.
//

#import "ZHDPComponent.h"
#import "ZHDPDataTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZHDPToast : ZHDPComponent
@property (nonatomic,copy) NSString *title;
@property (nonatomic,assign) ZHDPOutputType outputType;
@property (nonatomic,assign) NSTimeInterval animateDuration;
@property (nonatomic,assign) NSTimeInterval stayDuration;
@property (nonatomic,copy) void (^__nullable clickBlock) (void);
@property (nonatomic,copy) void (^__nullable showComplete) (void);
@property (nonatomic,copy) void (^__nullable hideComplete) (void);
- (void)show;
@end

NS_ASSUME_NONNULL_END
