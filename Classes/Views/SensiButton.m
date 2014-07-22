//
//  SensiButton.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "SensiButton.h"

#import <QuartzCore/QuartzCore.h>

#import "ConfigurationDataSource.h"
#import "PickyTextField.h"
#import "RHTPoint.h"
#import "SensirionDefaultTheme.h"

@interface SensiButton() <ValueHolder> {

    PickyTextField *_picker;
    UILabel *_valueLabel;
    RHTPoint *_currentData;

    BOOL _hasValues;
    BOOL _showValues;

    id<PickerViewDataSource> _dataSource;
}

@end

@implementation SensiButton

@synthesize displayType = _displayType;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupView];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        // Initialization code
        [self setupView];
    }

    return self;
}

- (void)setupView {
    _picker = [[PickyTextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [_picker setValueHodler:self];
    [_picker setHidden:YES];
    [self addSubview:_picker];

    [self addTarget:self action:@selector(displayPicker) forControlEvents:UIControlEventTouchUpInside];

    // background and borders
    [self setBackgroundColor:[UIColor SENSIRION_MIDDLE_GRAY]];
    [self.layer setCornerRadius:CONTROLS_CORNER_RADIUS];
    [self.layer setBorderWidth:CONTROLS_BORDER_WIDTH];
    [self.layer setBorderColor:[UIColor SENSIRION_DARK_GRAY].CGColor];
    self.clipsToBounds = YES;

    [SensirionDefaultTheme applyTheme:self.titleLabel];

    CGRect frame = [self frame];
    CGSize iconSize = CGSizeMake(30.0, 30.0);

    CGFloat leftPadding = 10.0;
    CGFloat rightPadding = leftPadding;

    UIFont *valueFont = [UIFont boldSystemFontOfSize:26];
    NSDictionary *valueAttributes = @{ NSFontAttributeName:valueFont };

    CGSize valueSize = [@"33.3 XX" sizeWithAttributes:valueAttributes];
    _valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - rightPadding - valueSize.width,
                                                            frame.size.height / 2 - valueSize.height / 2,
                                                            valueSize.width,
                                                            valueSize.height)];
    [_valueLabel setFont:valueFont];
    [_valueLabel setBackgroundColor:[UIColor clearColor]];
    [_valueLabel setTextColor:[UIColor blackColor]];
    [_valueLabel setTextAlignment:NSTextAlignmentCenter];
    [SensirionDefaultTheme applyTheme:_valueLabel];
    [self addSubview:_valueLabel];

    [self setImageEdgeInsets:UIEdgeInsetsMake(frame.size.height / 2 - iconSize.height/2,
                                              leftPadding,
                                              frame.size.height / 2 - iconSize.height/2,
                                              frame.size.width - iconSize.width - leftPadding)];

    [self setTitleEdgeInsets:UIEdgeInsetsMake(0,
                                              iconSize.width - leftPadding,
                                              0,
                                              _valueLabel.bounds.size.width)];

    [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];

    [self shouldShowValues:YES];
    [self updateValues];
    [self reload];
}

- (void)valueUpdated:(RHTPoint *)value {
    _currentData = value;
    _hasValues = YES;

    [self updateValues];
}

- (void)setDisplayType:(enum display_type)displayType {
    _displayType = displayType;
    [self updateValues];
}

- (enum display_type)displayType {
    return _displayType;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)shouldShowValues:(BOOL)enabled {
    _showValues = enabled;

    if (_showValues)
        _dataSource = [DisplayTypePickerDataSource sharedInstance];
    else
        _dataSource = [DisplayTypeWithUnitPickerDataSource sharedInstance];
}

- (void)updateValues {
    NSString *imageName;

    if (_displayType == DISPTYPE_TEMPERATURE) {
        imageName = @"ICONS_dark_T.png";
    } else {
        imageName = @"ICONS_dark_H.png";
    }

    [self setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [self bringSubviewToFront:self.imageView];

    [self setTitle:[_dataSource getTitleForValue:_displayType] forState:UIControlStateNormal];

    if (_showValues) {
        if (_hasValues) {
            switch (_displayType) {
                case DISPTYPE_TEMPERATURE:
                    [_valueLabel setText:[NSString stringWithFormat:@"%.01f %@", _currentData.temperature, [TemperatureConfigurationDataSource currentTemperatureUnitString]]];
                    break;
                case DISPTYPE_HUMIDITY:
                    [_valueLabel setText:[NSString stringWithFormat:@"%.01f %@", _currentData.relativeHumidity, relativeHumidityUnitString]];
                    break;
                case DISPTYPE_DEW_POINT:
                    [_valueLabel setText:[NSString stringWithFormat:@"%.01f %@", _currentData.dew_point, [TemperatureConfigurationDataSource currentTemperatureUnitString]]];
                    break;
                default:
                    [NSException raise:@"Unhandled display type" format:@"Display type %d", _displayType];
                    break;
            }
        } else {
            [_valueLabel setText:@"--.-"];
        }
    } else {
        [_valueLabel setText:@""];
    }

    [SensirionDefaultTheme applyTheme:self.titleLabel];
    [self setNeedsDisplay];
}

- (void)displayPicker {
    [_picker setDataSource:_dataSource];
    [_picker onValueUpdated:_displayType];
    [_picker becomeFirstResponder];
}

- (void)setShortValue:(uint16_t)value sender:(id)sender {
    NSLog(@"setShortValue called");
    if (sender == _picker) {
        _displayType = (enum display_type)value;

        if ([self delegate]) {
            [[self delegate] onSelection:value sender:self];
        }

        [self reload];
    }
}

- (void)clearValues {
    _currentData = nil;
    _hasValues = NO;

    [self setNeedsDisplay];
}

- (void)reload {
    [self updateValues];
}

@end
