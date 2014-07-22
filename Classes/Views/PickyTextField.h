//
//  PickyTextField.h
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ConfigurationDataSource.h"

@protocol ValueHolder
@required
- (void)setShortValue:(uint16_t)value sender:(id)sender;
@end

@interface PickyTextField : UITextField<UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property id<ValueHolder> valueHodler;

@property id<PickerViewDataSource> dataSource;

- (void)onValueUpdated:(uint16_t)value;

@end
