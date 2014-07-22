//
//  AlertViewController.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "BLEConnector.h"

@interface AlertViewController : NSObject

+ (void)onBleConnectionStateChanged:(ConnectorState)state;

+ (void)onDeleteDataFromPhoneMemoryConfirmRequiredWithDelegate:(id)delegate;

+ (void)onLoggingEnabled:(BOOL)enabled confirmRequiredWithDelegate:(id)delegate;

+ (void)showToastWithText:(NSString *)text;

+ (void)quickHelp:(id)delegate;

@end
