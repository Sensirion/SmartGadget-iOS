//
//  DateAndTimeView.m
//  sensible
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

@interface DateAndTimeView () {
    NSTimer *mTimer;

    NSDateFormatter *dateFormatter;

    UILabel *mWeekdayLabel;
    UILabel *mMonthOfYear;
    UILabel *mDayOfMonth;
    UILabel *mTimeLabel;
}

@end

@implementation DateAndTimeView


static int DATE_VERTICAL_OFFSET = -9;

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

- (void)chageColorAndShadowOf:(UILabel *)l {
    [l setShadowColor:[UIColor SENSIRION_LIGHT_GRAY]];
    [l setShadowOffset:CGSizeMake(1, 1.5)];
    [l setTextColor:[UIColor SENSIRION_TEXT_GRAY]];
}

- (void)initSubViews {
    mTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self selector:@selector(setTime) userInfo:nil repeats:YES];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:locale];
    [dateFormatter setDateFormat:@"EEEE"];


    // background and borders
    [self setBackgroundColor:[UIColor SENSIRION_MIDDLE_GRAY]];
    self.layer.cornerRadius = CONTROLS_CORNER_RADIUS;
    [self.layer setBorderWidth:CONTROLS_BORDER_WIDTH];
    [self.layer setBorderColor:[UIColor SENSIRION_DARK_GRAY].CGColor];
    self.clipsToBounds = YES;

    UIFont *dayFont = [UIFont boldSystemFontOfSize:54];
    UIFont *timeFont = [UIFont boldSystemFontOfSize:32];
    //UIFont *timeFont = [UIFont fontWithName:@"DBLCDTempBlack" size:42.0];

    CGSize weekdaySize = [@"XXX" sizeWithFont:dayFont];

    mWeekdayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
            0,
            self.frame.size.width / 2.2,
            weekdaySize.height)];

    [mWeekdayLabel setBackgroundColor:[UIColor clearColor]];
    [mWeekdayLabel setTextColor:[UIColor blackColor]];
    [mWeekdayLabel setFont:dayFont];
    [mWeekdayLabel setTextAlignment:NSTextAlignmentCenter];
    // [mWeekdayLabel setM :NSTextAlignmentLeft];
    [self chageColorAndShadowOf:mWeekdayLabel];


    [self addSubview:mWeekdayLabel];

    UIFont *monthDayTextLabelFont = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    UIFont *monthDayLabelFont = [UIFont boldSystemFontOfSize:20];

    CGSize monthSize = [@"Month" sizeWithFont:monthDayTextLabelFont];
    UILabel *monthLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
            weekdaySize.height + DATE_VERTICAL_OFFSET,
            self.frame.size.width / 4,
            monthSize.height)];

    [monthLabel setBackgroundColor:[UIColor clearColor]];
    [monthLabel setTextColor:[UIColor blackColor]];
    [monthLabel setText:@"Month"];
    [monthLabel setFont:monthDayTextLabelFont];
    [monthLabel setTextAlignment:NSTextAlignmentCenter];
    [self chageColorAndShadowOf:monthLabel];
    [self addSubview:monthLabel];

    monthSize = [@"33" sizeWithFont:monthDayLabelFont];

    mMonthOfYear = [[UILabel alloc] initWithFrame:CGRectMake(0,
            weekdaySize.height + monthLabel.frame.size.height + DATE_VERTICAL_OFFSET,
            self.frame.size.width / 4,
            monthSize.height)];

    [mMonthOfYear setBackgroundColor:[UIColor clearColor]];
    [mMonthOfYear setTextColor:[UIColor blackColor]];
    [mMonthOfYear setFont:monthDayLabelFont];
    [mMonthOfYear setTextAlignment:NSTextAlignmentCenter];
    [self chageColorAndShadowOf:mMonthOfYear];


    [self addSubview:mMonthOfYear];

    CGSize daySize = [@"Day" sizeWithFont:monthDayTextLabelFont];

    UILabel *dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width / 4,
            weekdaySize.height + DATE_VERTICAL_OFFSET,
            self.frame.size.width / 4,
            daySize.height)];

    [dayLabel setBackgroundColor:[UIColor clearColor]];
    [dayLabel setTextColor:[UIColor blackColor]];
    [dayLabel setText:@"Day"];
    [dayLabel setFont:monthDayTextLabelFont];
    [dayLabel setTextAlignment:NSTextAlignmentCenter];
    [self chageColorAndShadowOf:dayLabel];

    [self addSubview:dayLabel];

    mDayOfMonth = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width / 4,
            weekdaySize.height + dayLabel.frame.size.height + DATE_VERTICAL_OFFSET,
            self.frame.size.width / 4,
            monthSize.height)];

    [mDayOfMonth setBackgroundColor:[UIColor clearColor]];
    [mDayOfMonth setTextColor:[UIColor blackColor]];
    [mDayOfMonth setFont:monthDayLabelFont];
    [mDayOfMonth setTextAlignment:NSTextAlignmentCenter];
    [self chageColorAndShadowOf:mDayOfMonth];

    [self addSubview:mDayOfMonth];

    UIImageView *clockIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Time_white.png"]];
    [clockIcon setFrame:CGRectMake(self.frame.size.width * 0.53 - clockIcon.frame.size.width / 2,
            self.frame.size.height * 0.5 - clockIcon.frame.size.height / 2,
            clockIcon.frame.size.width,
            clockIcon.frame.size.height)];
    [self addSubview:clockIcon];


    CGSize timeSize = [@"33:33" sizeWithFont:timeFont];

    mTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 + clockIcon.frame.size.width / 1.67,
            (self.frame.size.height / 2) - (timeSize.height / 2),
            self.frame.size.width / 2 - clockIcon.frame.size.width,
            timeSize.height)];

    [mTimeLabel setBackgroundColor:[UIColor clearColor]];
    [mTimeLabel setTextColor:[UIColor blackColor]];
    [mTimeLabel setFont:timeFont];
    [mTimeLabel setTextAlignment:NSTextAlignmentCenter];
    [self chageColorAndShadowOf:mTimeLabel];
    [self addSubview:mTimeLabel];

    [self setTime];
}

- (void)setTime {
    NSDate *now = [NSDate date];
    NSCalendar *myCalendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [myCalendar components:NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:now];

    int hourOfDay = [components hour];
    int minuteOfHour = [components minute];
    int dayOfMonth = [components day];
    int monthOfYear = [components month];
    int dayInWeek = [components weekday];

    [mTimeLabel setText:[NSString stringWithFormat:@"%02d:%02d h", hourOfDay, minuteOfHour]];
    [mWeekdayLabel setText:[[dateFormatter shortWeekdaySymbols] objectAtIndex:dayInWeek - 1]];
    [mDayOfMonth setText:[NSString stringWithFormat:@"%02d", dayOfMonth]];
    [mMonthOfYear setText:[NSString stringWithFormat:@"%02d", monthOfYear]];
}

@end
