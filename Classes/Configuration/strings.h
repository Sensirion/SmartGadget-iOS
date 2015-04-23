//
//  strings.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#ifndef smartgadgetapp_strings_h
#define smartgadgetapp_strings_h

/* Settings, about texts, privacy policy, quick help */
static NSString *const aboutDescription = @"The Smart Gadget App is used to interact with the Sensirion Smart Gadget and the TI BLE Sensor Tag.</br>For further information and help, please visit:</br><a href=\"http://smart.sensirion.com/gadget\">http://smart.sensirion.com/gadget</a>";
static NSString *const aboutCompany = @"Sensirion AG, Switzerland</p>";

static NSString *const privacyPolicy = @"Bluetooth Low Energy (BLE) is used for data transfer between the Smart Gadget and the mobile device. Data is stored locally on the mobile device.";

static NSString *const quickHelpMessage = @"For information on how to connect to your Smart Gadgets, how to download and display data as well as general hints about the app, please check the About text in the Settings tab.";

/* Alerts, error messages */
static NSString *const gadgetDisconnected = @"Smart Gadget has been disconnected.";

static NSString *const goingToDownloadMany = @"You are going to download %u datapoints from your Smart Gadget. This may take a while...";

static NSString *const loggerStartedRecently = @"Logger on Smart Gadget has been started recently. There is no new data available for download.";

static NSString *const noDataAvailable = @"There is no data available for display. Go to Settings \uFFEB Gadgets to download data from your Smart Gadget.";

static NSString *const settingInterval = @"Setting new interval...";

static NSString *const noDataAvailableSinceLastDownload = @"There is no new data available since the last download";

static NSString *const deleteDataConfirmation = @"Do you really want to delete all the data downloaded from this Smart Gadget to the phone? (This action takes no effect on the data still stored on the Smart Gadget)";

static NSString *const loggingIntervalUnchangableWhileLogging = @"The logging interval can only be changed when logging is disabled. Disable logging first.";

static NSString *const enablingWillDiscardGadgetDataWarning = @"Enabling logging discards all the data currently stored on the Smart Gadget. Do you want to continue?";

static NSString *const disablingWillDiscardGadgetDataWarning = @"Disabling and enabling logging discards all the data stored on the Smart Gadget. Do you want to continue?";

static NSString *const signalLostWhileConnecting = @"Smart Gadget signal lost while connecting.";

static NSString *const haveToAllowBLE = @"You must turn on Bluetooth on your phone in order to connect to your Smart Gadget.";
static NSString *const haveToAllowBLEDialogTitle = @"Enable Bluetooth";

static NSString *const haveToAllowBLEPeripheral = @"You must allow this app to connect to your Smart Gadget.";
static NSString *const haveToAllowBLEPeripheralTitle = @"Bluetooth Authorization";

static NSString *const deviceNotSupportBLE = @"This device does not support Bluetooth Low Energy (BLE)";
static NSString *const deviceNotSupportBLETitle = @"Bluetooth Support";

/* Variable GUI Labels */
static NSString *const gadgetDoesNotSupportLogging = @"Smart Gadget without logger.";
static NSString *const youAreDownloadingFromOtherGadget = @"Other download in progress.";

/* Visible Gadget List */
static NSString *const gadgetCellIdentifier = @"GadgetCell";
static NSString *const searchIdentifier = @"Searching";
static NSString *const connectedIdentifier = @"Connected";
static NSString *const connectedAndDownloadingIdentifier = @"Connected, downloading";

/* History, incomplete list */
static NSString *const loadingData = @"Loading data...";
static NSString *const noDataConnectedGraphTitle = @"No data downloaded yet.";
static NSString *const gadgetIdNotAvailable = @"No Smart Gadget selected.";
static NSString *const showingDataFrom = @"Data from Smart Gadget ";

/* Comfort zone */
static NSString *const rheumatism = @"Rheumatic Pains";
static NSString *const respiratory = @"Respiratory Problems";
static NSString *const heatStroke = @"Heat Stroke";
static NSString *const dehydration = @"Dehydration";

/* Dashboard */
static NSString *const month = @"Month";
static NSString *const day = @"Day";

/* Humidity labels */
static NSString *const relativeHumidityTitle = @"Humidity";
static NSString *const dewPointTitle = @"Dew Point";
static NSString *const heatIndexTitle = @"Heat Index";
static NSString *const relativeHumidityUnitString = @"%";

/* Seasons */
static NSString *const seasonSummer = @"Summer";
static NSString *const seasonWinter = @"Winter";

/* Configuration data sources */
static NSString *const seasonTitle = @"Season";
static NSString *const comfortZoneTitle = @"Comfort Zone to display";
static NSString *const temperatureTitle = @"Temperature";
static NSString *const temperatureUnitTitle = @"Unit to display";
static NSString *const titleMissing = @"Title missing";

static NSString *const unitSecond = @"second";
static NSString *const unitSeconds = @"seconds";
static NSString *const unitMinute = @"minute";
static NSString *const unitMinutes = @"minutes";
static NSString *const unitHour = @"hour";
static NSString *const unitHours = @"hours";

static NSString *const okTitle = @"OK";
static NSString *const cancelTitle = @"Cancel";

#endif
