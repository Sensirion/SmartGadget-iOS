//
//  HumiService.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BLEProperty.h"

@class RHTPoint;

@protocol HumiServiceProtocol <NSObject>

@required
@property(readonly) BOOL hasLiveDataValues;
@property(readonly) RHTPoint *currentValue;

- (void)setNotify:(BOOL)notify;

@end