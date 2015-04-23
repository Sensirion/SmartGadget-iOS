//
//  LogDataViewController.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SensiButton.h"

@class BLEGadget;
@class CPTGraphHostingView;

@interface LogDataViewController : UIViewController

@property(strong, nonatomic) IBOutlet UIView *mainView;

@property(weak, nonatomic) IBOutlet CPTGraphHostingView *graphHostView;
@property(weak, nonatomic) IBOutlet UIButton *updateDataButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *selectDataNavigationButton;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *graphLoadingSpinner;
@property(weak, nonatomic) IBOutlet SensiButton *whatIsDisplayedButton;

- (IBAction)onDataClearButtonPushed:(id)sender;

- (IBAction)onDataUpdateButtonPressed:(id)sender;

- (void)setWhatDisplaysGraph:(enum display_type)display;

@end
