//
//  GadgetData.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@class MeasurementDataPoint;

@interface GadgetData : RLMObject

@property long long gadget_id;
@property long lastPointer;
@property NSString *lastKnownUUID;

@end

RLM_ARRAY_TYPE(GadgetData) // define RLMArray<GadgetData>