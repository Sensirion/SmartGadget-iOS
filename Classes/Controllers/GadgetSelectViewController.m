//
//  GadgetSelectViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "GadgetSelectViewController.h"

#import "BLEConnector.h"
#import "GadgetDetailsViewController.h"
#import "Settings.h"

@interface GadgetSelectViewController () <BLEConnectorDelegate> {

    UIImage *_connection1_Image;
    UIImage *_connection2_Image;
    UIImage *_connection3_Image;
    UIImage *_connection4_Image;

    NSTimer *_refreshTimer;
}

@end

@implementation GadgetSelectViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _connection1_Image = [UIImage imageNamed:@"connection_1.png"];
    _connection2_Image = [UIImage imageNamed:@"connection_2.png"];
    _connection3_Image = [UIImage imageNamed:@"connection_3.png"];
    _connection4_Image = [UIImage imageNamed:@"connection_4.png"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[BLEConnector sharedInstance] addListener:self];
    [[BLEConnector sharedInstance] startScanning];
    [self onStartRefreshTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self onStopRefreshTimer];
    [[BLEConnector sharedInstance] stopScanning];
    [[BLEConnector sharedInstance] removeListener:self];
}

- (void)onStartRefreshTimer {
    _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(onRefresh:) userInfo:nil repeats:YES];
}

- (void)onStopRefreshTimer {
    [_refreshTimer invalidate];
}

- (void)onResetRefreshTimer {
    [self onStopRefreshTimer];
    [self onStartRefreshTimer];
}

- (void)onRefresh:(NSTimer *)timer {
    [self.tableView reloadData];
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onGadgetListsUpdated {
    [self onResetRefreshTimer];

    NSLog(@"Selection list is reloading data");
    [self.tableView reloadData];
    [self.stillSearchingActivityIndicator startAnimating];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3; // connected + found gadgets + searching...
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [[[BLEConnector sharedInstance] connectedGadgets] count];
        case 1:
            return [[[BLEConnector sharedInstance] foundHumiGadgets] count];
        case 2:
            return 1; // always show "searching..." at end
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BLEGadget *gadget;
    NSUInteger row = (NSUInteger) [indexPath row];

    if ([indexPath section] == 0) {
        if ([[BLEConnector sharedInstance] connectedGadgets].count > row) {
            gadget = (BLEGadget *) [[BLEConnector sharedInstance] connectedGadgets][row];
        }
    } else if ([indexPath section] == 1) {
        if ([[BLEConnector sharedInstance] foundHumiGadgets].count > row) {
            gadget = (BLEGadget *) [[BLEConnector sharedInstance] foundHumiGadgets][row];
        }
    } else {
        //searching...
        return [tableView dequeueReusableCellWithIdentifier:searchIdentifier];
    }

    if (gadget) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:gadgetCellIdentifier];

        if ([gadget isConnected]) {
            [[cell textLabel] setText:[gadget description]];
            [[cell detailTextLabel] setText:connectedIdentifier];
            if (gadget.identifier && gadget.identifier == [Settings userDefaults].currentlyIsDownloading) {
                [[cell detailTextLabel] setText:connectedAndDownloadingIdentifier];
            }
        } else {
            if ([[gadget description] length] > 0) {
                [[cell textLabel] setText:[gadget description]];
            } else {
                [[cell textLabel] setText:[gadget peripheralName]];
            }

            [[cell detailTextLabel] setText:[NSString stringWithFormat:@"Not Connected RSSI: %@", gadget.RSSI]];
        }

        if ([gadget.RSSI intValue] > -41) {
            cell.imageView.image = _connection4_Image;
        } else if ([gadget.RSSI intValue] > -55) {
            cell.imageView.image = _connection3_Image;
        } else if ([gadget.RSSI intValue] > -71) {
            cell.imageView.image = _connection2_Image;
        } else {
            cell.imageView.image = _connection1_Image;
        }

        return cell;

    } else {
        //fallback if count has dropped since "numberOfRowsInSection" was called
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nil"];
    }
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
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowDetails"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSArray *gadgetArray;

        if ([indexPath section] == 0) {
            gadgetArray = [[BLEConnector sharedInstance] connectedGadgets];
        } else {
            gadgetArray = [[BLEConnector sharedInstance] foundHumiGadgets];
        }

        BLEGadget *gadget;

        if (gadgetArray && gadgetArray.count > indexPath.row) {
            gadget = gadgetArray[(NSUInteger) indexPath.row];
        }

        [((GadgetDetailsViewController *) segue.destinationViewController) setSelectedGadget:gadget];

    } else {
        NSLog(@"Unhandled segue %@", [segue identifier]);
    }
}

@end
