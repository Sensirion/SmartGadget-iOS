//
//  BLEConnector.h
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEGadget.h"

typedef enum BLEConnectorStates {
    POWER_ON,
    POWER_OFF,
    UNAUTHORIZED,
    UNSUPPORTED
} ConnectorState;

@protocol BLEConnectorDelegate
@required
- (void)onGadgetListsUpdated;
@end

@interface BLEConnector : NSObject

+ (BLEConnector *)sharedInstance;

/* Visible, but not connected gadgets */
@property (readonly) NSArray *foundHumiGadgets;

/* Vissible, and at the moment connected gadgets */
@property (readonly) NSArray *connectedGadgets;

- (void)addListener:(id<BLEConnectorDelegate>)listener;
- (void)removeListener:(id<BLEConnectorDelegate>)listener;

- (void)onEnterBackground;
- (void)onEnterForground;

- (void)startScanning;
- (void)stopScanning;

/**
 * Method to automatically connect to gadget with "strongest signal".
 */
- (void)autoConnect;

- (BLEGadget *)getConnectedGadget:(NSString *)gadgetUUID;
- (BLEGadget *)getConnectedGadgetWithSystemId:(uint64_t)identifier;

@end
