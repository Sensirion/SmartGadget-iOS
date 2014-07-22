//
//  BLEProperty.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BLEProperty <NSObject>

@required
@property (readonly) BOOL hasValue;

@end

@protocol BOOLProperty <BLEProperty>

@required
- (BOOL)getBool;

@end

@protocol MutableBOOLProperty <BOOLProperty>

@required
- (void)setBool:(BOOL)value;

@end

@protocol UInt32Property <BLEProperty>

@required
- (uint32_t)getValue;

@end

@protocol MutableUInt32Property <UInt32Property>

@required
- (void)setValue:(uint32_t)value;

@end

@protocol UInt16Property <BLEProperty>

@required
- (uint16_t)getShort;

@end

@protocol MutableUInt16Property <UInt16Property>

@required
- (void)setShort:(uint16_t)value;

@end

@protocol UInt8Property <BLEProperty>

@required
- (uint8_t)getExtraShort;

@end

@protocol MutableUInt8Property <UInt8Property>

@required
- (void)setExtraShort:(uint8_t)value;

@end
