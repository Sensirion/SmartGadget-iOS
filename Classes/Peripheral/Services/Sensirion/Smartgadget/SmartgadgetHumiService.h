//
// Created by Xavier Fernandez on 25/02/15.
// Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HumiService.h"
#import "BleService.h"

static NSString *const SMART_HUMIGADGET_NAME = @"Smart Humigadget";

@protocol SmartgadgetHumiServiceProtocol <HumiServiceProtocol>
@end