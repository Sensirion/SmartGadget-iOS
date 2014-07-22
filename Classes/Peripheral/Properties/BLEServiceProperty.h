//
//  BLEServiceProperty.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BLEProperty.h"

@class BLEGadget;
@class CBCharacteristic;

@interface BLEServiceProperty : NSObject<MutableBOOLProperty, MutableUInt8Property, MutableUInt16Property, MutableUInt32Property>

- (BLEServiceProperty *)init:(CBCharacteristic *)characteristic withParent:(BLEGadget *)parent;

- (BOOL)handleValueUpdated:(CBCharacteristic *)characteristic;

- (void)getValue:(void *)buffer length:(NSUInteger)length;
- (void)setValue:(void *)buffer length:(NSUInteger)length;


/* set value to nil and re-request value from peripheral... */
- (void)update;

/* re-request value from peripheral, but dont delete value before we will get new... */
- (void)updateEventualy;


@end
