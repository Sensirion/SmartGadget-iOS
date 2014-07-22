//
//  GadgetDetailsViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "GadgetDetailsViewController.h"

#import "AlertViewController.h"
#import "BLEConnector.h"
#import "LogDataViewController.h"
#import "Settings.h"

@interface GadgetDetailsViewController() <GadgetNotificationDelegate, LogDataNotificationProtocol, UIAlertViewDelegate, ValueHolder>
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
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];

    [self.downloadDataButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [self.disconnectButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    [self.downloadDataButton setEnabled:NO];
    [self.loggingIntervalLabel setEnabled:NO];
    [self.intervalPicker setEnabled:NO];
    [self.gadgetLoggingLabel setEnabled:NO];
    [self.descriptionTextField setEnabled:NO];

    [self.intervalPicker setDataSource:[LoggingIntervalPickerDataSource sharedInstance]];
    [self.intervalPicker setValueHodler:self];
    [self.intervalPicker setDelegate:self];

    [self.descriptionTextField setDelegate:self];

    // set to Left or Right    
    [[self navigationItem] setRightBarButtonItem:barButton];

    [activityIndicator startAnimating];

    if (self.selectedGadget) {

        if (![self.selectedGadget isConnected]) {
            NSLog(@"Trying to connect to gadget");
            [self.selectedGadget tryConnect];
        }
        
        NSLog(@"Showing details for gadget with UUID: %@", self.selectedGadget.UUID);

        [self descriptionUpdated:self.selectedGadget];
        [self gadgetHasNewValues:self.selectedGadget forService:nil];

        [self.selectedGadget addListener:self];
        
        [[self.selectedGadget LoggerService] notifyOnSynch:self];
        
        if ([[self.selectedGadget LoggerService] isSynchronizing]) {
            [self.downloadDataButton setEnabled:NO];
        }

    } else {
        NSLog(@"No gadget selected to show settings for");
        [AlertViewController showToastWithText:signalLostWhileConnecting];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.selectedGadget removeListener:self];
    [[self navigationItem] setRightBarButtonItem:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if (self.selectedGadget.BatteryService) {
        [self.batteryLevelLabel setHidden:NO];
        [self.batteryLevelIndicator setHidden:NO];
        [self.batteryLevelIndicator setProgress:[self.selectedGadget.BatteryService batteryLevel]];
    }
    
    if ([self.selectedGadget isConnected]) {
        [self.disconnectButton setEnabled:YES];
        [self.connectingActive stopAnimating];
        
        // can we start downlading right now??
        if ([[self.selectedGadget LoggerService] isSynchronizing]) {
            NSLog(@"INFO: selected gadget is already syncing");
        } else {
            [self.downloadDataButton setEnabled:YES];
        }

        if ([self.selectedGadget LoggerService]) {

            [[self.selectedGadget LoggerService] notifyOnSynch:self];

            if (self.selectedGadget.LoggerService.enabledHasValue) {
                [self.loggingSwitch setEnabled:YES];
                [self.loggingSwitch setOn:[[self.selectedGadget LoggerService] enabled] animated:NO];

                if ([self.selectedGadget.LoggerService.interval hasValue]) {
                    [self.intervalPicker setEnabled:YES];
                    [self.intervalPicker onValueUpdated:[self.selectedGadget.LoggerService.interval getShort]];
                }

                if ([Settings userDefaults].currentlyIsDownloading) {
                    [self.downloadDataButton setTitle:youAreDownloadingFromOtherGadget forState:UIControlStateDisabled];
                    [self.downloadDataButton setEnabled:NO];
                } else {
                    [self.downloadDataButton setEnabled:YES];
                    [self.loggingIntervalLabel setEnabled:YES];
                    [self.intervalPicker setEnabled:YES];
                    [self.gadgetLoggingLabel setEnabled:YES];
                }
            } else {
                [self.loggingSwitch setEnabled:NO];
                [self.downloadDataButton setTitle:gadgetDoesNotSupportLogging forState:UIControlStateDisabled];
                [self.downloadDataButton setEnabled:NO];
                [self.loggingIntervalLabel setEnabled:NO];
                [self.intervalPicker setEnabled:NO];
                [self.gadgetLoggingLabel setEnabled:NO];
            }
        }
    } else {
        [self.downloadDataButton setEnabled:NO];
        [self.disconnectButton setEnabled:NO];
    }
}

- (void)descriptionUpdated:(BLEGadget *)gadget {
    if ([self.selectedGadget isEqual:gadget]) {
        if ([@"" isEqualToString:[self.selectedGadget description]]) {
            //description not set
        } else {
            [self.descriptionTextField setEnabled:YES];
            [self.descriptionTextField setText:self.selectedGadget.description];
            
            //remove connection indicator for navigationbar when description is resolved
            [[self navigationItem] setRightBarButtonItem:nil];
        }
    }
}

- (void)gadgetDidDisconnect:(BLEGadget *)gadget {
    if ([self.selectedGadget isEqual:gadget]) {
        NSLog(@"Current gadget was disconnected");
        [AlertViewController showToastWithText:gadgetDisconnected];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self.descriptionTextField isEqual:textField]) {
        self.selectedGadget.description = [self.descriptionTextField text];

        //in case of setting a blank text, the default description is reloaded
        [self.descriptionTextField setText:self.selectedGadget.description];

        [textField resignFirstResponder];
        return YES;
    }
    
    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {    
    if ([self.intervalPicker isEqual:textField]) {
        if (self.loggingSwitch.on) {
            [AlertViewController showToastWithText:loggingIntervalUnchangableWhileLogging];
            return NO;
        }
    }

    return YES;
}

- (void)setShortValue:(uint16_t)value sender:(id)sender {
    if (sender == self.intervalPicker) {
        [self.selectedGadget.LoggerService.interval setShort:value];
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
        NSLog(@"Logging swithc changed: Proceed");
        if (self.selectedGadget) {
            NSLog(@"Starting updating logger state to: %s...", self.loggingSwitch.on ? "ON" : "OFF");
            NSLog(@"Logger service pointer is: %@...", self.selectedGadget.LoggerService );

            //only alow interval changes while not loggin
            [self.intervalPicker setEnabled:!self.loggingSwitch.on];
            [self.selectedGadget.LoggerService setEnabled:self.loggingSwitch.on];
        }
    }
}

- (IBAction)onDisconnectPressed:(id)sender {
    [self.selectedGadget forceDisconnect];
}

- (IBAction)onDownloadDataPressed:(id)sender {
    
    [self.downloadDataButton setEnabled:NO];
    NSLog(@"Sync required pushed...");
    if (self.selectedGadget) {
        if ([self.selectedGadget LoggerService]) {
            if ([[self.selectedGadget LoggerService] trySynchronizeData]) {
                [self.downloadDataButton setTitle:@"Initializing..." forState:UIControlStateDisabled];
                [self.downloadDataButton setEnabled:NO];
            } else {
                NSLog(@"INFO: synch data could not be started.");
            }
        }
    }
}

// DataNotification protocol implementation...

- (void)onLogDataSynchProgress:(CGFloat)progress {
    [self.downloadDataButton setEnabled:NO];

    [self.dataLoadingProgress setProgress:progress animated:YES];
    [self.downloadDataButton setTitle:[NSString stringWithFormat:@"Downloading... %d%%", (int)roundf(100 * progress)] forState:UIControlStateDisabled];
}

- (void)onLogDataSynchFinished {
    NSLog(@"Progress finished...");
    [self.dataLoadingProgress setProgress:1.0 animated:YES];
    [self.downloadDataButton setEnabled:YES];
}

@end
