//
//  BLEUtil.h
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>

@interface BLEUtil : NSObject

+ (UInt16)swap:(UInt16)s;

+ (CBService *)findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p;

+ (CBCharacteristic *)findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService *)service;

+ (NSString *)UUIDToString:(CFUUIDRef)UUID;

+ (const char *)CBUUIDToString:(CBUUID *)UUID;

+ (BOOL)compareCBUUID:(CBUUID *)UUID1 UUID2:(CBUUID *)UUID2;

+ (BOOL)compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2;

+ (UInt16)CBUUIDToInt:(CBUUID *)UUID;

+ (BOOL)UUIDSAreEqual:(CFUUIDRef)u1 u2:(CFUUIDRef)u2;

+ (void)printPeripheralInfo:(CBPeripheral *)peripheral;

+ (NSArray *)getAdvertisedServices:(NSDictionary *)advertisementData;

@end
