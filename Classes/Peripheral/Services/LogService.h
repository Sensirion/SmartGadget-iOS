//
// Created by Xavier Fernandez on 06/02/15.
// Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogServiceDelegate.h"

@class CBDescriptor;
@class CBCharacteristic;

@protocol LogServiceProtocol

@required
- (BOOL)trySynchronizeData;

- (void)setInterval:(uint32_t)intervalInMilliseconds;

- (void)notifyOnSync:(id <LogDataNotificationProtocol>)callback;

- (void)onCharacteristicWrite:(CBCharacteristic *)characteristic;

@property(readonly) BOOL loggingStateCanBeModified;
@property(readonly) BOOL loggingIsEnabledHasValue;
@property BOOL loggingIsEnabled;
@property(readonly) NSUInteger getIntervalMs;
@property(readonly) NSUInteger savedDataPoints;
@property(readonly) BOOL isSynchronizing;

@end