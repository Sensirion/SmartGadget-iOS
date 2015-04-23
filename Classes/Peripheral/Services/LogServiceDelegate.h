//
// Created by Xavier Fernandez on 06/02/15.
// Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LogDataNotificationProtocol

@required
- (void)onLogDataSyncProgress:(CGFloat)progress;

- (void)onLogDataSyncFinished;

- (void)onLogDataInfoSyncFinished;
@end
