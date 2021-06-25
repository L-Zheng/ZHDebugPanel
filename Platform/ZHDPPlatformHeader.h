//
//  ZHDPPlatformHeader.h
//  Pods
//
//  Created by EM on 2021/6/25.
//

#ifndef ZHDPPlatformHeader_h
#define ZHDPPlatformHeader_h


#if TARGET_OS_IPHONE

#define ZH_TARGET_OS_IPHONE TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define ZHView UIView
#define ZHColor UIColor
#define ZHTableView UITableView
#define ZHEdgeInsets UIEdgeInsets
#define ZHLabel UILabel
#define zh_willMoveToSuperview willMoveToSuperview
#define zh_didMoveToSuperview didMoveToSuperview

#elif TARGET_OS_MAC

#define ZH_TARGET_OS_MAC TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#define ZHView NSView
#define ZHColor NSColor
#define ZHTableView NSTableView
#define ZHEdgeInsets NSEdgeInsets
#define ZHLabel ZHLabel_Mac
#define zh_willMoveToSuperview viewWillMoveToSuperview
#define zh_didMoveToSuperview viewDidMoveToSuperview

#endif



#endif /* ZHDPPlatformHeader_h */
