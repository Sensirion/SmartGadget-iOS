//
//  GadgetDataRepository.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GadgetData.h"

@class NSManagedObjectContext;

@interface GadgetDataRepository : NSObject

+ (GadgetDataRepository *)sharedInstance;

- (void)setManagedObjectContext:(NSManagedObjectContext *)context;

- (void)addDataPoint:(NSDate *)timestamp withTemp:(float)temp andHumidity:(float)humidity toGadgetWithId:(uint64_t)gadgetId;

- (NSArray *)getData:(uint64_t)gadgetId;

- (NSDate *)getMinOrMaxTime:(BOOL)getMin forGadget:(uint64_t)gadgetId;

- (BOOL)hasData:(uint64_t)gadgetId;

- (NSArray *)getAllRecords;

- (NSArray *)getGadgetsWithSomeDownloadedData;

- (NSUInteger)savedMeasurmentsCountForGadgetWithId:(uint64_t)gadgetId;

- (void)cleanAllDataOfGadgetWithId:(uint64_t)gadgetId;

- (NSUInteger)getLastSynchPointForGadgetWithId:(uint64_t)gadgetId;

- (void)setLastSynchPoint:(NSUInteger)lastPoint forGadgetWithId:(uint64_t)gadgetId;

- (uint64_t)getGadgetIdFor:(NSString *)UUID;

- (void)updateLastKnownUUID:(NSString *)UUID forGadget:(uint64_t)gadgetId;

- (BOOL)save:(GadgetData *)gadgetData;

@end
