//
//  BLEGadget.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HumiService.h"
#import "BatteryService.h"
#import "LoggerService.h"
#import "GadgetSettingsService.h"
#import "GadgetNotificationDelegate.h"

@class CBPeripheral;
@class CBCharacteristic;

@protocol GadgetConnectionCallbackDelegate <NSObject>

@required
- (void)onGadgetConnectionDecayed:(BLEGadget *)gadget;

- (void)connect:(CBPeripheral *)peripheral;
- (void)forceDisconnect:(CBPeripheral *)peripheral;

@end

@interface BLEGadget : NSObject

+ (BOOL)isPartOf:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData;
+ (NSArray *)handledServiceIds;
+ (NSString *)discriptionFromId:(uint64_t)gadgetId;

@property (readonly) NSNumber *RSSI;
@property (readonly) NSString *UUID;
@property (readonly) NSString *peripheralName;
@property (readonly) BOOL isConnected;
@property (readonly) uint64_t identifier;
@property NSString *description;

- (id)initWithPeripheral:(CBPeripheral *)peripheral andManager:(id<GadgetConnectionCallbackDelegate>)manager;

- (void)setDisconnectedSignalStrength:(NSNumber *)RSSI;

- (NSComparisonResult)compare:(BLEGadget *)otherObject;

- (void)addListener:(id<GadgetNotificationDelegate>)delegate;
- (void)removeListener:(id<GadgetNotificationDelegate>)delegate;
- (BOOL)hasListener:(id<GadgetNotificationDelegate>)delegate;

- (BOOL)handleConnected:(CBPeripheral *)peripheral;
- (BOOL)handleDisconnected:(NSString *)peripheralUUID;

/* Behave properly when heading into and out of the background */
- (void)enteredBackground;
- (void)enteredForeground;

- (void)tryConnect;
- (void)forceDisconnect;

- (id<HumiServiceProtocol>)HumiService;

- (BatteryService *)BatteryService;

- (LoggerService *)LoggerService;

- (GadgetSettingsService *)SettingsService;

// child services convenience methods

- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic;

- (void)setNotifyValue:(BOOL)notify forCharacteristic:(CBCharacteristic *)characteristic;

- (void)writeValue:(NSData *)value forCharacteristic:(CBCharacteristic *)characteristic;

- (void)onLogDataSynchronized;

@end
