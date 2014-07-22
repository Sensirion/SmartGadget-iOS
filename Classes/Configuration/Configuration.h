//
//  Configuration.h
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "colors.h"
#import "strings.h"

/**
 * filter strange values, that can ocur if something on gadget went wrong,
 * e.g., logging is fast and there is intensive comunication with several devices
 * so the the processor does not handle all updates properly
 */
static const BOOL FILTER_DATA_FOR_STRANGE_VALUES = YES;

static const int CONTROLS_CORNER_RADIUS = 7;
static const float CONTROLS_BORDER_WIDTH = 0.8F;
static const float MIN_TEMPERATURE_SUMMER = 13.5;
static const float MAX_TEMPERATURE_SUMMER = 35;
static const float MIN_TEMPERATURE_WINTER = 11;
static const float MAX_TEMPERATURE_WINTER = 32.5;
static const float DOUBLE_TAP_INTERVAL = 0.20;
static const float SHOW_PROGRESS_MIN_TIME = 3.0;
static const float LOGO_SIZE = 32.0;
static const float DEFAULT_TIME_TO_HIDE_TOAST = 3.0;
static const float DEFAULT_AUTO_CONNECT_TIMER = 2.0;

static const uint LOGG_INTERVAL_VALUES[] = {1u, 10u, 60u, 10*60u, 60*60u, 3*60*60u};

enum comfort_zone_type {
    SEASON_SUMMER,
    SEASON_WINTER,
    comfort_zone_type_count
};

enum temperature_unit_type {
    UNIT_CELCIUS,
    UNIT_FARENHEIT,
    temperature_unit_type_count
};

enum display_type {
    DISPTYPE_TEMPERATURE,
    DISPTYPE_HUMIDITY,
    DISPTYPE_DEW_POINT,
    display_type_count
};