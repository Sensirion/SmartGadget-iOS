//
//  GadgetNotificationDelegate.h
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEGadget.h"

@class BLEGadget;

@protocol GadgetNotificationDelegate <NSObject>

- (void)descriptionUpdated:(BLEGadget *)gadget;

- (void)gadgetHasNewValues:(BLEGadget *)gadget forService:(id)service;

- (void)gadgetDidDisconnect:(BLEGadget *)gadget;

@end
