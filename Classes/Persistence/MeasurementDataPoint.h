//
//  MeasurementDataPoint.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@class GadgetData;

@interface MeasurementDataPoint : RLMObject

@property float humidity;
@property float temperature;
@property NSDate *timestamp;
@property GadgetData *gadget;

@end

RLM_ARRAY_TYPE(MeasurementDataPoint) // define RMLArray<GadgetData>