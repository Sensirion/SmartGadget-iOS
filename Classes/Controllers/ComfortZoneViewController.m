//
//  ComfortZoneViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "ComfortZoneViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "BLEConnector.h"
#import "ConfigurationDataSource.h"
#import "RHTPoint.h"
#import "Settings.h"

@interface ComfortZoneViewController() <BLEConnectorDelegate, GadgetNotificationDelegate>
@end

@implementation ComfortZoneViewController

- (void)viewDidLoad {    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Create and initialize a tap gesture
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(onTapGraph:)];
    
    // Specify that the gesture must be a single tap
    tapRecognizer.numberOfTapsRequired = 1;
    
    // Add the tap gesture recognizer to the grid view
    [self.graphView addGestureRecognizer:tapRecognizer];
    
    CGAffineTransform rotation = CGAffineTransformMakeRotation(-M_PI / 2);
    
    [self.nameLabel setTransform:rotation];
    [self.tempLabel setTransform:rotation];
    [self.rhLabel setTransform:rotation];
    
    [self.colorIndicator.layer setCornerRadius:6];
    [self.colorIndicator.layer setBorderWidth:1.5F];
    [self.colorIndicator.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.colorIndicator.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.colorIndicator.layer setShadowOpacity:1];
    [self.colorIndicator.layer setShadowRadius:1.0];
    [self.colorIndicator.layer setShadowOffset:CGSizeMake(1.0, 1.0)];
    [self.colorIndicator setBackgroundColor:[UIColor grayColor]];
    [self.colorIndicator setEnabled:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.graphView setupSubViews];
    
    [[BLEConnector sharedInstance] addListener:self];
    
}

- (void)viewDidAppear:(BOOL)animated {   
    [self onGadgetListsUpdated];
    
    [self.graphView setSelectedUUID:[[Settings userDefaults] selectedGadgetUUID]];
}

- (void)viewDidDisappear:(BOOL)animated {    
    while (self.graphView.selectedUUID) {
        BLEGadget *selected = [[BLEConnector sharedInstance] getConnectedGadget:self.graphView.selectedUUID];
        [selected.HumiService setNotifiy:NO];
        [self gadgetDidDisconnect:selected];
    }
    
    [[BLEConnector sharedInstance] removeListener:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setBackgroundImageView:nil];
    [self setGraphContainerView:nil];
    [self setGraphView:nil];
    [self setColorIndicator:nil];
    [self setNameLabel:nil];
    [self setTempLabel:nil];
    [self setRhLabel:nil];
    [self setLogoLabel:nil];
    [super viewDidUnload];
}

- (void)onGadgetListsUpdated {
    NSArray *connected = [BLEConnector sharedInstance].connectedGadgets;
    
    for (BLEGadget *gadget in connected) {
        
        //check if gadgets are already tracked...
        if ([gadget hasListener:self]) {
            continue;
        }
        
        [self connectedToGadget:gadget];

        //fake update
        [self gadgetHasNewValues:gadget forService:gadget.HumiService];
    }
}

- (void)connectedToGadget:(BLEGadget *)gadget {
    [gadget addListener:self];
    [gadget.HumiService setNotifiy:YES];
    
    UIColor *color = [[Settings userDefaults] getColorForGadget:gadget.UUID];
    
    [self.graphView addIndicator:gadget.UUID withColor:color];
    
    if ([[gadget HumiService] hasSensorValues]) {
        
        RHTPoint *current = [gadget HumiService].currentValue;
        [self.graphView updateIndicator:gadget.UUID withTemp:current.temperature andHumidity:current.relativeHumidity withAnimation:NO];
    }
    
    //update info since the last added gadget will be the "selected one"
    [self refreshInfoFields];
}

- (void)gadgetDidDisconnect:(BLEGadget *)gadget {
    [gadget removeListener:self];
    [self.graphView removeIndicator:gadget.UUID];
    
    //in case selected gadget was removed.
    [self refreshInfoFields];
}

- (void)gadgetHasNewValues:(BLEGadget *)gadget forService:(id)service {    
    if ([service respondsToSelector:@selector(temperature)]) {
        
        if (((id<HumiServiceProtocol>)service).hasSensorValues) {
            
            RHTPoint *value = ((id<HumiServiceProtocol>)service).currentValue;
            [self.graphView updateIndicator:gadget.UUID withTemp:value.temperature andHumidity:value.relativeHumidity withAnimation:YES];
            
            if ([gadget.UUID isEqualToString:self.graphView.selectedUUID]) {
                [self setInfoFieldsFor:gadget.description value:value];
            }
        }
    }
}

- (void)descriptionUpdated:(BLEGadget *)gadget {
    if ([gadget.UUID isEqualToString:self.graphView.selectedUUID]) {
        [self.nameLabel setText:gadget.description];
    }
}

- (IBAction)onTapGraph:(id)sender {
    [self.graphView cycleSelectedIndicator];
    [[Settings userDefaults] setSelectedGadgetUUID:self.graphView.selectedUUID];
    
    [self refreshInfoFields];
}

- (void)refreshInfoFields {
    if (self.graphView.selectedUUID) {
        // get selected humiservice
        BLEGadget *selectedGadget = [[BLEConnector sharedInstance] getConnectedGadget:self.graphView.selectedUUID];
        
        [self.colorIndicator setBackgroundColor:[[Settings userDefaults] getColorForGadget:selectedGadget.UUID]];
        
        if ([selectedGadget.HumiService hasSensorValues]) {
            
            RHTPoint *value = selectedGadget.HumiService.currentValue;
            [self setInfoFieldsFor:selectedGadget.description value:value];
        } else {
            [self setInfoFieldsFor:selectedGadget.description value:nil];
        }
        
    } else {
        //nothing is selected
        [self resetInfoFields];
    }
}

- (void)resetInfoFields {
    [self.tempLabel setText:@"--.--"];
    [self.rhLabel setText:@"--.--"];
    [self.nameLabel setText:@""];
    [self.colorIndicator setBackgroundColor:[UIColor grayColor]];
}

- (void)setInfoFieldsFor:(NSString *)name value:(RHTPoint *)currentValue {
    //refresh fields with new info
    [self.nameLabel setText:name];

    if (currentValue) {
        NSString *tempUnit = [TemperatureConfigurationDataSource currentTemperatureUnitString];
        NSString *rhUnit = @"%RH";
        [self.tempLabel setText:[NSString stringWithFormat:@"%.01f %@", currentValue.temperature, tempUnit]];
        [self.rhLabel setText:[NSString stringWithFormat:@"%.00f %@", currentValue.relativeHumidity, rhUnit]];
    } else {
        [self.tempLabel setText:@"--.--"];
        [self.rhLabel setText:@"--.--"];    
    }
}

@end
