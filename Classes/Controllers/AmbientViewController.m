//
//  AmbientViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "AmbientViewController.h"

#import "AlertViewController.h"
#import "BLEConnector.h"
#import "BLEGadget.h"
#import "Settings.h"
#import "RHTPoint.h"

#import <QuartzCore/QuartzCore.h>

@interface AmbientViewController () <GadgetNotificationDelegate, BLEConnectorDelegate, SelectionDelegate, UITableViewDelegate, UITableViewDataSource>
@end

@implementation AmbientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    NSString *logoText = @"<name>";
    [self.logoLabel setText:logoText];

    [self.upperButton setDisplayType:DISPTYPE_TEMPERATURE];
    [self.upperButton setDelegate:self];

    [self.lowerButton setDisplayType:DISPTYPE_HUMIDITY];
    [self.lowerButton setDelegate:self];

    if ([[Settings userDefaults] isFirstTime]) {
        NSLog(@"Running for the first time...");
        [AlertViewController quickHelp:self];
    } else {
        NSLog(@"Not a first time run...");
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //not first time any more, quick help was dismissed
}

- (void)viewDidAppear:(BOOL)animated {
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
    if (self.selectedGadget) {
        [self.selectedGadget removeListener:self];
        [[self.selectedGadget HumiService] setNotifiy:NO];
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
    [self setLowerButton:nil];
    [self setUpperButton:nil];
    [self setLogoLabel:nil];
    [self setConnectedGadgetTable:nil];
    [super viewDidUnload];
}

- (void)onGadgetListsUpdated {

    if ([[BLEConnector sharedInstance].connectedGadgets count] > 0) {
        self.selectedGadget = [[BLEConnector sharedInstance] getConnectedGadget:[[Settings userDefaults] selectedGadgetUUID]];

        if (self.selectedGadget) {
            [self.selectedGadget addListener:self];
            [[self.selectedGadget HumiService] setNotifiy:YES];
        }
    } else {
        self.selectedGadget = nil;
        [self.upperButton clearValues];
        [self.lowerButton clearValues];
    }

    [self.connectedGadgetTable reloadData];
}

- (void)gadgetDidDisconnect:(BLEGadget *)gadget {
    [AlertViewController showToastWithText:gadgetDisconnected];

    [self.upperButton clearValues];
    [self.lowerButton clearValues];
}

- (void)descriptionUpdated:(BLEGadget *)gadget {
    [self.connectedGadgetTable reloadData];
}

- (void)gadgetHasNewValues:(BLEGadget *)gadget forService:(id)service {
    if ([service respondsToSelector:@selector(temperature)]) {

        id<HumiServiceProtocol> humiService = ((id<HumiServiceProtocol>)service);

        [self.upperButton valueUpdated:humiService.currentValue];
        [self.lowerButton valueUpdated:humiService.currentValue];
    }
}

- (void)onSelection:(uint16_t)value sender:(SensiButton *)sender {
    if (sender == self.upperButton) {
        [Settings userDefaults].upperMainButonDisplayes = (enum display_type)value;
    } else if (sender == self.lowerButton) {
        [Settings userDefaults].lowerMainButonDisplayes = (enum display_type)value;
    }
}

//----------------------
// TableViewDataSource
//----------------------

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[BLEConnector sharedInstance] connectedGadgets] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BLEGadget *gadget = (BLEGadget *)[[[BLEConnector sharedInstance] connectedGadgets] objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GadgetCell"];

    if (![[gadget description] isEqualToString:@""] && ![[gadget description] isEqualToString:@"NULL"]) {
        [[cell textLabel] setText:gadget.description];
    } else {
        [[cell textLabel] setText:@"Loading description"];
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

    [[cell  imageView].layer setCornerRadius:10];
    [cell imageView].image = image;	

    if ([gadget.UUID isEqualToString:[[Settings userDefaults] selectedGadgetUUID]])
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    else
        [cell setAccessoryType:UITableViewCellAccessoryNone];

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
    BLEGadget *gadget = (BLEGadget *)[[[BLEConnector sharedInstance] connectedGadgets] objectAtIndex:indexPath.row];
    [[Settings userDefaults] setSelectedGadgetUUID:gadget.UUID];
    [self.connectedGadgetTable reloadData];

    if (self.selectedGadget) {
        [self.selectedGadget removeListener:self];
        [[self.selectedGadget HumiService] setNotifiy:NO];
    }

    self.selectedGadget = gadget;
    [self.selectedGadget addListener:self];
    [[self.selectedGadget HumiService] setNotifiy:YES];
}

@end
