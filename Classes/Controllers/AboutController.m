//
//  AboutController.m
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import "AboutController.h"
#import "Settings.h"

@implementation AboutController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSString *spaceString = @" ";
    NSString *newLineString = @"\u2029";
    NSString *copyRightString = @"\u00A9";

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    NSString *yearString = [formatter stringFromDate:[NSDate date]];

    NSMutableString *aboutText = [[NSMutableString alloc] init];
    [aboutText setString:aboutDescription];
    [aboutText appendString:newLineString];
    [aboutText appendString:spaceString];
    [aboutText appendString:[AboutController versionBuild]];
    [aboutText appendString:spaceString];
    [aboutText appendString:copyRightString];
    [aboutText appendString:spaceString];
    [aboutText appendString:yearString];
    [aboutText appendString:spaceString];
    [aboutText appendString:aboutCompany];
    
    NSString *myDescriptionHTML = [NSString stringWithFormat:@"<html> \n"
     "<head> \n"
     "<style type=\"text/css\"> \n"
     "body {font-family: \"%@\"; font-size: %@;}\n"
     "</style> \n"
     "</head> \n"
     "<body>%@</body> \n"
     "</html>", @"helvetica", [NSNumber numberWithInt:16], aboutText];
    [self.webView loadHTMLString:myDescriptionHTML baseURL:nil];
    self.webView.delegate = self;

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

// open links/URL in Safari
- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if (inType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }

    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (NSString *)appName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

+ (NSString *)appVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSString *)build {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

+ (NSString *)versionBuild {
    NSString *appName = [self appName];
    NSString *version = [self appVersion];
    NSString *build = [self build];
    
    NSString *versionBuild = [NSString stringWithFormat:@"%@, version %@", appName, version];
    
    if (![version isEqualToString: build]) {
        versionBuild = [NSString stringWithFormat:@"%@ (%@)", versionBuild, build];
    }
    
    return versionBuild;
}

@end
