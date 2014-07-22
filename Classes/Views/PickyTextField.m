//
//  PickyTextField.m
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import "PickyTextField.h"

#import <QuartzCore/QuartzCore.h>

#import "colors.h"
#import "strings.h"

@interface PickyTextField() {

    id<PickerViewDataSource> _dataSource;
    UIPickerView *_picker;
    NSInteger _selectedRow;
}

@end

@implementation PickyTextField

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setUpInputView];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        //initialize
        [self setUpInputView];
    }

    return self;
}

- (void)setUpInputView {
    NSLog(@"Setting up input view");

    _picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 200, 320, 200)];
    _picker.dataSource = self;
    _picker.delegate = self;
    _picker.showsSelectionIndicator = YES;
    [self setInputView:_picker];

    UIToolbar *accessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    accessoryView.barStyle = UIBarStyleDefault;

    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onSelected:)];

    accessoryView.items = [NSArray arrayWithObjects:space, done, nil];
    [self setInputAccessoryView:accessoryView];

    [[self valueForKey:@"textInputTraits"] setValue:[UIColor clearColor] forKey:@"insertionPointColor"];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(paste:))
        return NO;

    if (action == @selector(cut:))
        return NO;
    
    if (action == @selector(copy:))
        return NO;

    return [super canPerformAction:action withSender:sender];
}

- (void)setDataSource:(id<PickerViewDataSource>)dataSource {
    _dataSource = dataSource;
    _selectedRow = [self.dataSource getDefaultValueRow];
    [_picker selectRow:_selectedRow inComponent:0 animated:NO];
}

- (id<PickerViewDataSource>)dataSource {
    return _dataSource;
}

- (void)onValueUpdated:(uint16_t)value {
    if ([self dataSource]) {
        [self setText:[self.dataSource getTitleForValue:value]];
    } else {
        [self setText:titleMissing];
    }
}

- (void)onSelected:(id)sender {
    NSLog(@"onSelected called");

    uint16_t selectedValue = [self.dataSource getValueForRow:_selectedRow];

    [self setText:[self.dataSource getTitleForValue:selectedValue]];
    [self.valueHodler setShortValue:selectedValue sender:self];
    [self resignFirstResponder];

    //reset "default selection"
    _selectedRow = [self.dataSource getDefaultValueRow];
    [_picker selectRow:_selectedRow inComponent:0 animated:NO];
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if ([self dataSource])
        return [self.dataSource numberOfValues];

    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if ([self dataSource])
        return [self.dataSource getTitleForRow:row];

    return titleMissing;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _selectedRow = row;
}

@end
