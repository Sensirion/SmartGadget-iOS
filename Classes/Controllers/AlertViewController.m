//
//  AlertViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "AlertViewController.h"
#import "Configuration.h"

static UIAlertView *CONNECTION_STATE_ALERT_VIEW;

@implementation AlertViewController

+ (void)onBleConnectionStateChanged:(ConnectorState)state {
    if (state == POWER_ON) {
        //all is well, clear alert view if it appeared earlier
        if (CONNECTION_STATE_ALERT_VIEW) {
            [CONNECTION_STATE_ALERT_VIEW dismissWithClickedButtonIndex:CONNECTION_STATE_ALERT_VIEW.cancelButtonIndex animated:YES];
            CONNECTION_STATE_ALERT_VIEW = nil;
        }

        return;
    }

    NSString *title;
    NSString *message;

    switch (state) {

        case POWER_OFF:
            title = haveToAllowBLEDialogTitle;
            message = haveToAllowBLE;
            break;

        case UNAUTHORIZED:
            title = haveToAllowBLEPeripheralTitle;
            message = haveToAllowBLEPeripheral;
            break;

        case UNSUPPORTED:
            title = deviceNotSupportBLETitle;
            message = deviceNotSupportBLE;
            break;

        default:
            [NSException raise:@"Unsupported value" format:@"Implementation missing for %u", state];
            break;
    }

    CONNECTION_STATE_ALERT_VIEW = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:okTitle otherButtonTitles:nil];
    [CONNECTION_STATE_ALERT_VIEW show];
}

+ (void)onDeleteDataFromPhoneMemoryConfirmRequiredWithDelegate:(id)delegate {
    NSString *message = deleteDataConfirmation;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:delegate cancelButtonTitle:cancelTitle otherButtonTitles:okTitle, nil];
    [alert show];
}

+ (void)onLoggingEnabled:(BOOL)enabled confirmRequiredWithDelegate:(id)delegate {
    NSString *message;
    if (enabled) {
        message = enablingWillDiscardGadgetDataWarning;
    } else {
        message = disablingWillDiscardGadgetDataWarning;
    }

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:delegate cancelButtonTitle:cancelTitle otherButtonTitles:okTitle, nil];
    [alertView show];
}

+ (void)quickHelp:(id)delegate {
    NSLog(@"Quick help..");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:quickHelpMessage delegate:delegate cancelButtonTitle:okTitle otherButtonTitles:nil];
    [alertView show];
}

+ (void)showToastWithText:(NSString *)text {
    NSLog(@"Starting to show toast");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:text delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alertView show];

    NSTimer *timer = [NSTimer timerWithTimeInterval:DEFAULT_TIME_TO_HIDE_TOAST target:self selector:@selector(hideAlert:) userInfo:alertView repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

+ (void)hideAlert:(NSTimer *)timer {
    NSLog(@"Time to hide toast");
    if (timer.userInfo != nil) {
        [(UIAlertView *) timer.userInfo dismissWithClickedButtonIndex:0 animated:YES];
    }
}

@end
