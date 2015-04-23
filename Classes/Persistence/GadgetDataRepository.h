//
//  GadgetDataRepository.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GadgetData.h"

@class NSManagedObjectContext;

@interface GadgetDataRepository : NSObject

+ (GadgetDataRepository *)sharedInstance;

- (void)addDataPoint:(NSDate *)timestamp withTemp:(float)temp andHumidity:(float)humidity toGadgetWithId:(long long)gadgetId;

- (NSArray *)getData:(long long)gadgetId;

- (NSDate *)getMinOrMaxTime:(BOOL)getMin forGadget:(long long)gadgetId;

- (BOOL)hasData:(long long)gadgetId;

- (NSArray *)getAllRecords;

- (NSArray *)getGadgetsWithSomeDownloadedData;

- (long)savedMeasurementsCountForGadgetWithId:(long long)gadgetId;

- (void)cleanAllDataOfGadgetWithId:(long long)gadgetId;

- (long)getLastSyncPointForGadgetWithId:(long long)gadgetId;

- (void)setLastSyncPoint:(long)lastPoint forGadgetWithId:(long long)gadgetId;

- (long long)getGadgetIdFor:(NSString *)UUID;

- (void)updateLastKnownUUID:(NSString *)UUID forGadget:(long long)gadgetId;

@end
