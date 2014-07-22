//
//  LoggerService.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "BLEService.h"
#import "BLEProperty.h"

@class CBUUID;
@class GadgetData;

@protocol LogDataNotificationProtocol <NSObject>

@required
- (void)onLogDataSynchProgress:(CGFloat)progress;
- (void)onLogDataSynchFinished;

@end

@interface LoggerService : BLEService

+ (CBUUID *)serviceId;

@property (readonly) BOOL enabledHasValue;
@property BOOL enabled;
@property (readonly) id<MutableUInt16Property> interval;
@property (readonly) NSUInteger savedDataPoints;
@property (readonly) BOOL isSynchronizing;

/**
 * Will try to start a log download, returns NO if synch could not be started
 */
- (BOOL)trySynchronizeData;

- (void)notifyOnSynch:(id<LogDataNotificationProtocol>)callback;

@end
