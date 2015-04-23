//
//  SensiButton.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Configuration.h"

@class RHTPoint;
@class SensiButton;

@protocol SelectionDelegate
@required
- (void)onSelection:(uint16_t)value sender:(SensiButton *)sender;
@end

@interface SensiButton : UIButton

@property id <SelectionDelegate> delegate;

@property(nonatomic) enum display_type displayType;

- (void)valueUpdated:(RHTPoint *)value;

- (void)clearValues;

- (void)shouldShowValues:(BOOL)enabled;

- (void)reload;

@end
