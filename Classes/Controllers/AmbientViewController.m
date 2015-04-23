//
//  AmbientViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "AmbientViewController.h"

#import "AlertViewController.h"
#import "Settings.h"
#import "RHTPoint.h"

@interface AmbientViewController () <GadgetNotificationDelegate, BLEConnectorDelegate, SelectionDelegate, UITableViewDelegate, UITableViewDataSource>
@end

@implementation AmbientViewController {
    NSString *_description;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // set logo, "B" letter in this special font is whole logo
    NSString *logoText = @"B";
    UIFont *logoFont = [UIFont fontWithName:@"SensirionSimple" size:LOGO_SIZE];
    [self.logoLabel setText:logoText];
    [self.logoLabel setFont:logoFont];

    [self.temperatureButton setDisplayType:DISPTYPE_TEMPERATURE];
    [self.temperatureButton setDelegate:self];
    [self.temperatureButton setUserInteractionEnabled:NO];

    [self.humidityButton setDisplayType:DISPTYPE_HUMIDITY];
    [self.humidityButton setDelegate:self];
    [self.humidityButton setUserInteractionEnabled:NO];

    [self.dewPointButton setDisplayType:DISPTYPE_DEW_POINT];
    [self.dewPointButton setDelegate:self];
    [self.dewPointButton setUserInteractionEnabled:NO];

    [self.heatIndexButton setDisplayType:DISPTYPE_HEAT_INDEX];
    [self.heatIndexButton setDelegate:self];
    [self.heatIndexButton setUserInteractionEnabled:NO];

    if ([[Settings userDefaults] isFirstTime]) {
        NSLog(@"Running for the first time...");
        [AlertViewController quickHelp:self];
    } else {
        NSLog(@"Not a first time run...");
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([[[BLEConnector sharedInstance] connectedGadgets] count] == 0) {
        //try to "auto connect" to strongest signal
        [[BLEConnector sharedInstance] autoConnect];
    }

    [[BLEConnector sharedInstance] addListener:self];

    [self.connectedGadgetTable setDataSource:self];
    [self.connectedGadgetTable setDelegate:self];

    [self onGadgetListsUpdated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.selectedGadget) {
        [self.selectedGadget removeListener:self];
        [[self.selectedGadget HumiService] setNotify:NO];
    }

    //stop the scanning if still auto connecting
    [[BLEConnector sharedInstance] stopScanning];
    [[BLEConnector sharedInstance] removeListener:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setHumidityButton:nil];
    [self setTemperatureButton:nil];
    [self setDewPointButton:nil];
    [self setHeatIndexButton:nil];
    [self setLogoLabel:nil];
    [self setConnectedGadgetTable:nil];
    [super viewDidUnload];
}

- (void)onGadgetListsUpdated {

    if ([[BLEConnector sharedInstance].connectedGadgets count] > 0) {
        self.selectedGadget = [[BLEConnector sharedInstance] getConnectedGadget:[[Settings userDefaults] selectedGadgetUUID]];

        if (self.selectedGadget) {
            [self.selectedGadget addListener:self];
            [[self.selectedGadget HumiService] setNotify:YES];
        }
    } else {
        self.selectedGadget = nil;
        [self clearValues];
    }

    [self.connectedGadgetTable reloadData];
}

- (void)clearValues {
    [self.temperatureButton clearValues];
    [self.humidityButton clearValues];
    [self.dewPointButton clearValues];
    [self.heatIndexButton clearValues];
}

- (void)gadgetDidDisconnect:(BLEGadget *)gadget {
    [AlertViewController showToastWithText:gadgetDisconnected];
    [self clearValues];
}

- (void)descriptionUpdated:(BLEGadget *)gadget {
    [self.connectedGadgetTable reloadData];
}

- (void)gadgetHasNewValues:(BLEGadget *)gadget forService:(id)service {
    if ([service respondsToSelector:@selector(temperature)]) {

        id <HumiServiceProtocol> humiService = ((id <HumiServiceProtocol>) service);
        [self.temperatureButton valueUpdated:humiService.currentValue];
        [self.humidityButton valueUpdated:humiService.currentValue];
        [self.dewPointButton valueUpdated:humiService.currentValue];
        [self.heatIndexButton valueUpdated:humiService.currentValue];
    }
}

- (void)onSelection:(uint16_t)value sender:(SensiButton *)sender {
}

//----------------------
// TableViewDataSource
//----------------------

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[BLEConnector sharedInstance] connectedGadgets] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BLEGadget *gadget = (BLEGadget *) [[BLEConnector sharedInstance] connectedGadgets][(NSUInteger) indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GadgetCell"];


    if ([[gadget description] isEqualToString:@""] || [[gadget description] isEqualToString:@"NULL"]) {
        [[cell textLabel] setText:@"Loading description"];
    } else {
        [[cell textLabel] setText:gadget.description];
    }

    //color
    UIColor *color = [[Settings userDefaults] getColorForGadget:gadget.UUID];
    CGRect rect = CGRectMake(0, 0, 20, 20);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [[cell imageView].layer setCornerRadius:10];
    [cell imageView].image = image;

    if ([gadget.UUID isEqualToString:[[Settings userDefaults] selectedGadgetUUID]]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }

    [cell.layer setCornerRadius:CONTROLS_CORNER_RADIUS];
    [cell.layer setBorderColor:[UIColor SENSIRION_LIGHT_GRAY].CGColor];
    [cell.layer setMasksToBounds:YES];
    [cell.layer setBorderWidth:CONTROLS_BORDER_WIDTH];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    BLEGadget *gadget = (BLEGadget *) [[BLEConnector sharedInstance] connectedGadgets][(NSUInteger) indexPath.row];
    [[Settings userDefaults] setSelectedGadgetUUID:gadget.UUID];
    [self.connectedGadgetTable reloadData];

    if (self.selectedGadget) {
        [self.selectedGadget removeListener:self];
        [[self.selectedGadget HumiService] setNotify:NO];
    }

    self.selectedGadget = gadget;
    [self.selectedGadget addListener:self];
    [[self.selectedGadget HumiService] setNotify:YES];
    [self clearValues];
}

@end
