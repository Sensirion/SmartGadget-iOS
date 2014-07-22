//
//  GadgetDetailsViewController.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PickyTextField.h"

@class BLEGadget;

@interface GadgetDetailsViewController : UIViewController<UITextFieldDelegate>

@property (weak, nonatomic) BLEGadget *selectedGadget;

@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UISwitch *loggingSwitch;
@property (weak, nonatomic) IBOutlet UIButton *disconnectButton;
@property (weak, nonatomic) IBOutlet UILabel *batteryLevelLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *batteryLevelIndicator;
@property (weak, nonatomic) IBOutlet UIButton *downloadDataButton;
@property (weak, nonatomic) IBOutlet PickyTextField *intervalPicker;
@property (weak, nonatomic) IBOutlet UILabel *gadgetNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *gadgetLoggingLabel;
@property (weak, nonatomic) IBOutlet UILabel *loggingIntervalLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *dataLoadingProgress;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *connectingActive;

- (IBAction)loggingEnabledChanged:(id)sender;
- (IBAction)onDisconnectPressed:(id)sender;
- (IBAction)onDownloadDataPressed:(id)sender;

@end
