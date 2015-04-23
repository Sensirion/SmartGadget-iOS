//
//  Configuration.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "colors.h"
#import "strings.h"

/**
* filter strange values, that can occur if something on gadget went wrong,
* e.g., logging is fast and there is intensive communication with several devices
* so the the processor does not handle all updates properly
*/
static const BOOL FILTER_DATA_FOR_STRANGE_VALUES = YES;

static const int NR_POINTS_TO_REPORT = 100;
static const int CONTROLS_CORNER_RADIUS = 7;
static const float CONTROLS_BORDER_WIDTH = 0.8f;
static const float MIN_TEMPERATURE_SUMMER = 13.5f;
static const float MAX_TEMPERATURE_SUMMER = 35.0f;
static const float MIN_TEMPERATURE_WINTER = 11.0f;
static const float MAX_TEMPERATURE_WINTER = 32.5f;
static const float DOUBLE_TAP_INTERVAL = 0.20f;
static const float SHOW_PROGRESS_MIN_TIME_SECONDS = 3.0f;
static const float SHOW_PROGRESS_TIMEOUT_SECONDS = 10.0f;
static const float MINIMUN_TOAST_TIME_SECONDS = 1.5f;
static const float LOGO_SIZE = 32.0f;
static const float DEFAULT_TIME_TO_HIDE_TOAST = 3.0f;
static const float DEFAULT_AUTO_CONNECT_TIMER = 2.0f;

// 1 second, 10 seconds, 1 minute, 5 minutes, 10 minutes, 1 hour, 3 hours.
static const uint LOG_INTERVAL_VALUES[] = {1u, 10u, 60u, 5 * 60u, 10 * 60u, 60 * 60u, 3 * 60 * 60u};

enum comfort_zone_type {
    SEASON_SUMMER,
    SEASON_WINTER,
    comfort_zone_type_count
};

enum temperature_unit_type {
    UNIT_CELCIUS,
    UNIT_FAHRENHEIT,
    temperature_unit_type_count
};

enum display_type {
    DISPTYPE_TEMPERATURE,
    DISPTYPE_HUMIDITY,
    DISPTYPE_DEW_POINT,
    DISPTYPE_HEAT_INDEX,
    display_type_count
};