//
//  HumiService.h
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BLEProperty.h"

@class RHTPoint;

@protocol HumiServiceProtocol <NSObject>

@required
@property (readonly) BOOL hasSensorValues;
@property (readonly) RHTPoint *currentValue;

- (void)setNotifiy:(BOOL)notify;

@end
