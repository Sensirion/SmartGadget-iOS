//
//  GadgetDetailsViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "GadgetDetailsViewController.h"

#import "AlertViewController.h"
#import "LogDataViewController.h"
#import "MBProgressHUD.h"
#import "Settings.h"

@interface GadgetDetailsViewController () <GadgetNotificationDelegate, LogDataNotificationProtocol, UIAlertViewDelegate, ValueHolder, MBProgressHUDDelegate>{
    MBProgressHUD *_mProgressHUD;
    double _lastPetitionTime;
}
@end

@implementation GadgetDetailsViewController

- (id)init {
    self = [super init];
    if (self) {
        //initialize members
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];

    [[self downloadDataButton] setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [[self disconnectButton] setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    [[self downloadDataButton] setEnabled:NO];
    [[self loggingIntervalLabel] setEnabled:NO];
    [[self intervalPicker] setEnabled:NO];
    [[self gadgetLoggingLabel] setEnabled:NO];
    [[self descriptionTextField] setEnabled:NO];

    [[self intervalPicker] setDataSource:[LoggingIntervalPickerDataSource sharedInstance]];
    [[self intervalPicker] setValueHolder:self];
    [[self intervalPicker] setDelegate:self];

    [[self descriptionTextField] setDelegate:self];

    // set to Left or Right
    [[self navigationItem] setRightBarButtonItem:barButton];

    [activityIndicator startAnimating];

    if ([self selectedGadget]) {
        if (![[self selectedGadget] isConnected]) {
            NSLog(@"Trying to connect to gadget");
            [self.selectedGadget tryConnect];
        }

        NSLog(@"Showing details for gadget with UUID: %@", self.selectedGadget.UUID);

        [self descriptionUpdated:self.selectedGadget];
        [self gadgetHasNewValues:self.selectedGadget forService:nil];

        [self.selectedGadget addListener:self];

        [[[self selectedGadget] LoggerService] notifyOnSync:self];

        if ([[[self selectedGadget] LoggerService] isSynchronizing]) {
            [[self downloadDataButton] setEnabled:NO];
        }

    } else {
        NSLog(@"No gadget selected to show settings for");
        [AlertViewController showToastWithText:signalLostWhileConnecting];
        [[self navigationController] popViewControllerAnimated:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [[self selectedGadget] removeListener:self];
    [[self navigationItem] setRightBarButtonItem:nil];
}

- (void)viewDidUnload {
    [self setDescriptionTextField:nil];
    [self setLoggingSwitch:nil];
    [self setDisconnectButton:nil];
    [self setDownloadDataButton:nil];
    [self setIntervalPicker:nil];
    [self setBatteryLevelLabel:nil];
    [self setBatteryLevelIndicator:nil];
    [super viewDidUnload];
}

- (void)gadgetHasNewValues:(BLEGadget *)gadget forService:(id)service {
    if ([[self selectedGadget] BatteryService]) {
        [[self batteryLevelLabel] setHidden:NO];
        [[self batteryLevelIndicator] setHidden:NO];
        [[self batteryLevelIndicator] setProgress:[[[self selectedGadget] BatteryService] batteryLevel]];
    }

    if ([[self selectedGadget] isConnected]) {
        [[self disconnectButton] setEnabled:YES];
        [[self connectingActive] stopAnimating];

        id <LogServiceProtocol> gadgetLoggerService = [[self selectedGadget] LoggerService];

        if (gadgetLoggerService) {

            // can we start downloading right now??
            if ([gadgetLoggerService isSynchronizing]) {
                NSLog(@"INFO: selected gadget is already syncing");
            } else {
                [self.downloadDataButton setEnabled:YES];
            }

            [[[self selectedGadget] LoggerService] notifyOnSync:self];

            if ([[[self selectedGadget] LoggerService] loggingIsEnabledHasValue]) {

                if ([gadgetLoggerService loggingStateCanBeModified]) {
                    [[self loggingSwitch] setHidden:NO];
                    [[self loggingSwitch] setEnabled:YES];
                    [[self loggingSwitch] setOn:[gadgetLoggerService loggingIsEnabled] animated:NO];
                } else {
                    [[self loggingSwitch] setEnabled:NO];
                    [[self loggingSwitch] setOn:YES animated:NO];
                }

                if ([gadgetLoggerService getIntervalMs] > 0) {
                    [[self intervalPicker] setEnabled:YES];
                    [[self intervalPicker] onValueUpdated:(uint16_t) ([gadgetLoggerService getIntervalMs] / 1000)];
                }

                if ([[Settings userDefaults] currentlyIsDownloading]) {
                    [[self downloadDataButton] setTitle:youAreDownloadingFromOtherGadget forState:UIControlStateDisabled];
                    [[self downloadDataButton] setEnabled:NO];
                } else {
                    [[self downloadDataButton] setEnabled:YES];
                    [[self loggingIntervalLabel] setEnabled:YES];
                    [[self intervalPicker] setEnabled:YES];
                    if ([gadgetLoggerService loggingStateCanBeModified]) {
                        [[self gadgetLoggingLabel] setEnabled:YES];
                    }
                }
            } else {
                [[self loggingSwitch] setEnabled:NO];
                [[self downloadDataButton] setTitle:gadgetDoesNotSupportLogging forState:UIControlStateDisabled];
                [[self downloadDataButton] setEnabled:NO];
                [[self loggingIntervalLabel] setEnabled:NO];
                [[self intervalPicker] setEnabled:NO];
                [[self gadgetLoggingLabel] setEnabled:NO];
            }
        }
    } else {
        [[self downloadDataButton] setEnabled:NO];
        [[self disconnectButton] setEnabled:NO];
    }
}

- (void)descriptionUpdated:(BLEGadget *)gadget {
    if ([[self selectedGadget] isEqual:gadget]) {
        if ([@"" isEqualToString:[[self selectedGadget] description]]) {
            //description not set
        } else {
            [[self descriptionTextField] setEnabled:YES];
            [[self descriptionTextField] setText:[[self selectedGadget] description]];

            //remove connection indicator for the navigation bar when description is resolved
            [[self navigationItem] setRightBarButtonItem:nil];
        }
    }
}

- (void)gadgetDidDisconnect:(BLEGadget *)gadget {
    if ([[self selectedGadget] isEqual:gadget]) {
        NSLog(@"Current gadget was disconnected");
        [AlertViewController showToastWithText:gadgetDisconnected];
        [[self navigationController] popViewControllerAnimated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([[self descriptionTextField] isEqual:textField]) {
        [[self selectedGadget] setDescription:[[self descriptionTextField] text]];

        //in case of setting a blank text, the default description is reloaded
        [[self descriptionTextField] setText:[[self selectedGadget] description]];

        [textField resignFirstResponder];
        return YES;
    }

    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if ([self.intervalPicker isEqual:textField]) {
        if ([[[self selectedGadget] LoggerService] loggingStateCanBeModified]) {
            if (self.loggingSwitch.on) {
                [AlertViewController showToastWithText:loggingIntervalUnchangableWhileLogging];
                return NO;
            }
        }
    }
    return YES;
}

- (void)setShortValue:(uint16_t)value sender:(id)sender {
    if (sender == self.intervalPicker) {
        _lastPetitionTime = CACurrentMediaTime();
        _mProgressHUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_mProgressHUD];
        _mProgressHUD.delegate = self;
        _mProgressHUD.labelText = settingInterval;
        [_mProgressHUD show:true];
        [_mProgressHUD hide:YES afterDelay:SHOW_PROGRESS_TIMEOUT_SECONDS];
        [[[self selectedGadget] LoggerService] setInterval:(uint32_t) (value * 1000)];
    }
}

- (void)onLogDataInfoSyncFinished {
    NSLog(@"Interval was set succesfully");
    double waitTime = CACurrentMediaTime() - _lastPetitionTime;
    if (waitTime > MINIMUN_TOAST_TIME_SECONDS) {
        [_mProgressHUD hide: YES];
    } else {
        [_mProgressHUD hide: YES afterDelay: MINIMUN_TOAST_TIME_SECONDS - waitTime];
    }
}

- (IBAction)loggingEnabledChanged:(UISwitch *)sender {
    [AlertViewController onLoggingEnabled:sender.on confirmRequiredWithDelegate:self];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        NSLog(@"Logging switch changed: Canceled");
        self.loggingSwitch.on = !self.loggingSwitch.on;
    } else {
        NSLog(@"Logging switch changed: Proceed");
        if (self.selectedGadget) {
            NSLog(@"Starting updating logger state to: %s...", self.loggingSwitch.on ? "ON" : "OFF");
            NSLog(@"Logger service pointer is: %@...", self.selectedGadget.LoggerService);

            //Only allow getIntervalMs changes while not logging
            [[self intervalPicker] setEnabled:![[self loggingSwitch] isOn]];
            [[[self selectedGadget] LoggerService] setLoggingIsEnabled:[[self loggingSwitch] isOn]];
        }
    }
}

- (IBAction)onDisconnectPressed:(id)sender {
    [self.selectedGadget forceDisconnect];
}

- (IBAction)onDownloadDataPressed:(id)sender {
    [self.downloadDataButton setEnabled:NO];
    NSLog(@"Sync required pushed...");
    if ([self selectedGadget] && [[self selectedGadget] LoggerService]) {
        if ([[self.selectedGadget LoggerService] trySynchronizeData]) {
            [[self downloadDataButton] setTitle:@"Initializing..." forState:UIControlStateDisabled];
            [[self downloadDataButton] setEnabled:NO];
        } else {
            NSLog(@"INFO: synch data could not be started.");
        }
    }
}

// Data Notification protocol implementation...

- (void)onLogDataSyncProgress:(CGFloat)progress {
    [self.downloadDataButton setEnabled:NO];
    [self.dataLoadingProgress setProgress:progress animated:NO];
    [self.downloadDataButton setTitle:[NSString stringWithFormat:@"Downloading... %d%%", (int) roundf(100 * progress)] forState:UIControlStateDisabled];
    NSLog(@"Progress at %f%%.", progress * 100.0f);
}

- (void)onLogDataSyncFinished {
    NSLog(@"Progress finished...");
    [self.dataLoadingProgress setProgress:1.0 animated:YES];
    [self.downloadDataButton setEnabled:YES];
}

@end
