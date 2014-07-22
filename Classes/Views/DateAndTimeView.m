//
//  DateAndTimeView.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "DateAndTimeView.h"

#import <QuartzCore/QuartzCore.h>

#import "SensirionDefaultTheme.h"
#import "Settings.h"

static int DATE_VERTICAL_OFFSET = -9;

@interface DateAndTimeView () {
    NSTimer *_timer;

    NSDateFormatter* _dateFormatter;

    UILabel *_weekdayLabel;
    UILabel *_monthOfYearLabel;
    UILabel *_dayOfMonthLabel;
    UILabel *_timeLabel;
}

@end

@implementation DateAndTimeView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initSubViews];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];

    if (self) {
        [self initSubViews];
    }

    return self;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

- (void)initSubViews {
    _timer = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self selector:@selector(setTime) userInfo:nil repeats:YES];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setLocale:locale];
    [_dateFormatter setDateFormat:@"EEEE"];

    // background and borders
    [self setBackgroundColor:[UIColor SENSIRION_MIDDLE_GRAY]];
    [self.layer setCornerRadius:CONTROLS_CORNER_RADIUS];
    [self.layer setBorderWidth:CONTROLS_BORDER_WIDTH];
    [self.layer setBorderColor:[UIColor SENSIRION_DARK_GRAY].CGColor];
    self.clipsToBounds = YES;

    UIFont *dayFont = [UIFont boldSystemFontOfSize:54];
    NSDictionary *dayAttributes = @{ NSFontAttributeName:dayFont };
    UIFont *timeFont = [UIFont boldSystemFontOfSize:32];
    NSDictionary *timeAttributes = @{ NSFontAttributeName:timeFont };

    CGSize weekdaySize = [@"XXX" sizeWithAttributes:dayAttributes];

    _weekdayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                              0,
                                                              self.frame.size.width / 2.2,
                                                              weekdaySize.height)];
    [_weekdayLabel setBackgroundColor:[UIColor clearColor]];
    [_weekdayLabel setTextColor:[UIColor blackColor]];
    [_weekdayLabel setFont:dayFont];
    [_weekdayLabel setTextAlignment:NSTextAlignmentCenter];
    [SensirionDefaultTheme applyTheme:_weekdayLabel];
    [self addSubview:_weekdayLabel];

    UIFont *monthDayTextLabelFont = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    NSDictionary *monthDayTextLabelAttributes = @{ NSFontAttributeName:monthDayTextLabelFont };
    UIFont *monthDayLabelFont = [UIFont boldSystemFontOfSize:20];
    NSDictionary *monthDayLabelAttributes = @{ NSFontAttributeName:monthDayLabelFont };

    CGSize monthSize = [month sizeWithAttributes:monthDayTextLabelAttributes];
    UILabel *monthLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,
                                                                   weekdaySize.height + DATE_VERTICAL_OFFSET,
                                                                   self.frame.size.width / 4,
                                                                   monthSize.height)];
    [monthLabel setBackgroundColor:[UIColor clearColor]];
    [monthLabel setTextColor:[UIColor blackColor]];
    [monthLabel setText:month];
    [monthLabel setFont:monthDayTextLabelFont];
    [monthLabel setTextAlignment:NSTextAlignmentCenter];
    [SensirionDefaultTheme applyTheme:monthLabel];
    [self addSubview:monthLabel];

    monthSize = [@"33" sizeWithAttributes:monthDayLabelAttributes];

    _monthOfYearLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                  weekdaySize.height + monthLabel.frame.size.height + DATE_VERTICAL_OFFSET,
                                                                  self.frame.size.width / 4,
                                                                  monthSize.height)];
    [_monthOfYearLabel setBackgroundColor:[UIColor clearColor]];
    [_monthOfYearLabel setTextColor:[UIColor blackColor]];
    [_monthOfYearLabel setFont:monthDayLabelFont];
    [_monthOfYearLabel setTextAlignment:NSTextAlignmentCenter];
    [SensirionDefaultTheme applyTheme:_monthOfYearLabel];
    [self addSubview:_monthOfYearLabel];

    CGSize daySize = [day sizeWithAttributes:monthDayTextLabelAttributes];

    UILabel *dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width / 4,
                                                                  weekdaySize.height + DATE_VERTICAL_OFFSET,
                                                                  self.frame.size.width / 4,
                                                                  daySize.height)];
    [dayLabel setBackgroundColor:[UIColor clearColor]];
    [dayLabel setTextColor:[UIColor blackColor]];
    [dayLabel setText:day];
    [dayLabel setFont:monthDayTextLabelFont];
    [dayLabel setTextAlignment:NSTextAlignmentCenter];
    [SensirionDefaultTheme applyTheme:dayLabel];
    [self addSubview:dayLabel];

    _dayOfMonthLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width / 4,
                                                                 weekdaySize.height + dayLabel.frame.size.height + DATE_VERTICAL_OFFSET,
                                                                 self.frame.size.width / 4,
                                                                 monthSize.height)];
    [_dayOfMonthLabel setBackgroundColor:[UIColor clearColor]];
    [_dayOfMonthLabel setTextColor:[UIColor blackColor]];
    [_dayOfMonthLabel setFont:monthDayLabelFont];
    [_dayOfMonthLabel setTextAlignment:NSTextAlignmentCenter];
    [SensirionDefaultTheme applyTheme:_dayOfMonthLabel];
    [self addSubview:_dayOfMonthLabel];

    UIImageView *clockIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ICONS_dark_clock.png"]];
    [clockIcon setFrame:CGRectMake(self.frame.size.width  * 0.53 - clockIcon.frame.size.width / 2,
                                   self.frame.size.height * 0.5 - clockIcon.frame.size.height / 2,
                                   clockIcon.frame.size.width,
                                   clockIcon.frame.size.height)];
    [self addSubview:clockIcon];

    CGSize timeSize = [@"33:33" sizeWithAttributes:timeAttributes];

    _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 + clockIcon.frame.size.width / 1.67,
                                                           (self.frame.size.height / 2) - (timeSize.height / 2),
                                                           self.frame.size.width / 2 - clockIcon.frame.size.width,
                                                           timeSize.height)];
    [_timeLabel setBackgroundColor:[UIColor clearColor]];
    [_timeLabel setTextColor:[UIColor blackColor]];
    [_timeLabel setFont:timeFont];
    [_timeLabel setTextAlignment:NSTextAlignmentCenter];
    [SensirionDefaultTheme applyTheme:_timeLabel];
    [self addSubview:_timeLabel];

    [self setTime];
}

- (void)setTime {
    NSDate *now = [NSDate date];
    NSCalendar *myCalendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [myCalendar components:NSMonthCalendarUnit|NSWeekdayCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:now];

    int hourOfDay = (int)[components hour];
    int minuteOfHour = (int)[components minute];
    int dayOfMonth = (int)[components day];
    int monthOfYear = (int)[components month];
    int dayInWeek = (int)[components weekday];

    [_timeLabel setText:[NSString stringWithFormat:@"%02d:%02d h", hourOfDay, minuteOfHour]];
    [_weekdayLabel setText:[[_dateFormatter shortWeekdaySymbols] objectAtIndex:dayInWeek-1]];
    [_dayOfMonthLabel setText:[NSString stringWithFormat:@"%02d", dayOfMonth]];
    [_monthOfYearLabel setText:[NSString stringWithFormat:@"%02d", monthOfYear]];
}

@end
