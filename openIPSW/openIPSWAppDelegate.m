#import "openIPSWAppDelegate.h"
#import "MysqlConnection.h"
#import "MysqlFetch.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import "ASIDownloadCache.h"

@interface openIPSWAppDelegate ()
- (void)updateBandwidthUsageIndicator;
- (void)URLFetchWithProgressComplete:(ASIHTTPRequest *)request;
- (void)URLFetchWithProgressFailed:(ASIHTTPRequest *)request;
- (void)checkInternet;
@end

@implementation openIPSWAppDelegate

@synthesize window;
@synthesize button;
@synthesize jailbreakResult;
@synthesize jailbreakTool;
@synthesize unlockResult;
@synthesize unlockTool;
@synthesize infoSize;
@synthesize infoSHSH;
@synthesize infoBaseband;
@synthesize deviceBox;
@synthesize firmwareBox;
@synthesize bigFetchRequest;

NSString * const sqlHost = @"readonlyipsw.db.6730814.hostedresource.com";
NSString * const sqlPort = @"3306";
NSString * const sqlUser = @"readipsw";
NSString * const sqlPass = @"Read0nly";
NSString * const sqlDB = @"readonlyipsw";
NSString * tool_url;
NSString * unlock_url;
NSString * ipsw_url;
NSString * ipswName;
NSString * chosen_device;
NSString * chosen_firmware;
bool tethered;
bool updateNeeded;
NSNumber *firmware_version;
NSString * device_table;
NSString * location;
NSString * data[12];
NSTimer * updateTimer;

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    [window makeKeyAndOrderFront:self];
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self checkInternet];
    MysqlConnection *connection = [MysqlConnection connectToHost:sqlHost user:sqlUser password:sqlPass schema:sqlDB flags:MYSQL_DEFAULT_CONNECTION_FLAGS];
    MysqlFetch *deviceFetch = [MysqlFetch fetchWithCommand:@"SELECT device_name FROM 0_devices" onConnection:connection];
    for (NSDictionary *userRow in deviceFetch.results) {
        NSNumber *device_name = [userRow objectForKey:@"device_name"];
        [deviceBox addItemWithObjectValue:device_name];
    }
    [connection finalize];
    [progressIndicator setMinValue:0];
    [progressIndicator setMaxValue:100];
    [progressIndicator setDoubleValue:0];
    [startButton setEnabled:false];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if (location != nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@",[location stringByAppendingPathExtension:@"download"]] error:NULL];
    }
    return YES;
}

- (IBAction)deviceChanged:(id)sender {
    ipswName = nil;
    ipsw_url = nil;
    tool_url = nil;
    unlock_url = nil;
    [resumeButton setEnabled:false];
    [startButton setEnabled:false];
    [jailbreakResult setStringValue:@"X"];
    [jailbreakTool setTitle:@"X"];
    [unlockResult setStringValue:@"X"];
    [unlockTool setTitle:@"X"];
    [infoBaseband setStringValue:@"X"];
    [infoSHSH setStringValue:@"X"];
    [infoSize setStringValue:@"X"];
    [firmwareBox removeAllItems];
    firmwareBox.objectValue = NULL;
    NSString *device = deviceBox.objectValue;
    NSString *selectedDevice = [NSString stringWithFormat:@"SELECT device_table FROM 0_devices WHERE device_name='%@';", device];
    MysqlConnection *connection = [MysqlConnection connectToHost:sqlHost user:sqlUser password:sqlPass schema:sqlDB flags:MYSQL_DEFAULT_CONNECTION_FLAGS];
    MysqlFetch *firmwareFetch = [MysqlFetch fetchWithCommand:selectedDevice onConnection:connection];
    for (NSDictionary *userRow in firmwareFetch.results) {
        firmware_version = [userRow objectForKey:@"device_table"];
    }
    NSString *selectedDevice2 = [NSString stringWithFormat:@"SELECT CONCAT(version,' (',build,')') FROM %@;", firmware_version];
    MysqlFetch *newFetch = [MysqlFetch fetchWithCommand:selectedDevice2 onConnection:connection];
    for (NSDictionary *userRow in newFetch.results) {
        NSNumber *firmware_version2 = [userRow objectForKey:@"CONCAT(version,' (',build,')')"];
        [firmwareBox addItemWithObjectValue:firmware_version2];
    }
    [connection finalize];
    [firmwareBox setEnabled:true];
}

- (IBAction)firmwareSelected:(id)sender {
    ipswName = nil;
    ipsw_url = nil;
    long mID = (firmwareBox.indexOfSelectedItem + 1);
    NSString *versInfo = [NSString stringWithFormat:@"(SELECT can_jailbreak FROM `%@` WHERE id='%ld') UNION ALL (SELECT can_unlock FROM `%@` WHERE id='%ld') UNION ALL (SELECT baseband FROM `%@` WHERE id='%ld') UNION ALL (SELECT size FROM `%@` WHERE id='%ld') UNION ALL (SELECT tool FROM `%@` WHERE id='%ld') UNION ALL (SELECT unlock_tool FROM `%@` WHERE id='%ld') UNION ALL (SELECT tethered FROM `%@` WHERE id='%ld') UNION ALL (SELECT shsh FROM `%@` WHERE id='%ld');", firmware_version, mID, firmware_version, mID, firmware_version, mID, firmware_version, mID, firmware_version, mID, firmware_version, mID, firmware_version, mID, firmware_version, mID];
    NSString *urlInfo = [NSString stringWithFormat:@"(SELECT tool_url FROM `%@` WHERE id='%ld') UNION ALL (SELECT unlock_url FROM `%@` WHERE id='%ld') UNION ALL (SELECT url FROM `%@` WHERE id='%ld') UNION ALL (SELECT name FROM `%@` WHERE id='%ld');", firmware_version, mID, firmware_version, mID, firmware_version, mID, firmware_version, mID];
    MysqlConnection *connection = [MysqlConnection connectToHost:sqlHost user:sqlUser password:sqlPass schema:sqlDB flags:MYSQL_DEFAULT_CONNECTION_FLAGS];
    MysqlFetch *infoFetch = [MysqlFetch fetchWithCommand:versInfo onConnection:connection];
    int counter = 0;
    for (NSDictionary *newRow in infoFetch.results) {
        NSString *device_name = [newRow objectForKey:@"can_jailbreak"];
        data[counter] = [NSString stringWithFormat:@"%@", device_name];
        counter += 1;
    }
    MysqlFetch *urlFetch = [MysqlFetch fetchWithCommand:urlInfo onConnection:connection];
    for (NSDictionary *newRow in urlFetch.results) {
        NSString *urlResult = [newRow objectForKey:@"tool_url"];
        data[counter] = [NSString stringWithFormat:@"%@", urlResult];
        counter += 1;
    }
    [connection finalize];
    if ([data[6] isEqualToString:@"Yes"]) { tethered = 1; }
    else { tethered = 0; }
    if (tethered == true && [data[0] isEqualToString:@"Yes"]) { [jailbreakResult setStringValue:(@"Yes (Tethered)")]; }
    else if (tethered == false && [data[0] isEqualToString:@"Yes"]) { [jailbreakResult setStringValue:(@"Yes (Untethered)")]; }
    else { [jailbreakResult setStringValue:(data[0])]; }
    if (data[1].length == 0) { [unlockResult setStringValue:NSLocalizedString(@"No", "NO")]; }
    else { [unlockResult setStringValue:(data[1])]; }
    if (data[2].length == 0) { [infoBaseband setStringValue:NSLocalizedString(@"No", "NO")]; }
    else { [infoBaseband setStringValue:(data[2])]; }
    if (data[3].length == 0) { [infoSize setStringValue: @"X"]; }
    else {
        NSString *sizeWithMB = [NSString stringWithFormat:@"%@ MB", [data[3] substringWithRange:NSMakeRange(0, data[3].length - 8)]];
        [infoSize setStringValue:(sizeWithMB)];
    }
    if (data[4].length == 0) { [jailbreakTool setTitle:@"X"]; }
    else { [jailbreakTool setTitle:(data[4])]; }
    if (data[5].length == 0) { [unlockTool setTitle:@"X"]; }
    else { [unlockTool setTitle:(data[5])]; }
    if (data[7].length == 0) { [infoSHSH setStringValue:NSLocalizedString(@"X", "NO")]; }
    else { [infoSHSH setStringValue:(data[7])]; }
    if (data[8].length == 0) { [jailbreakTool setStringValue:@"X"]; }
    else { tool_url = [NSString stringWithString:data[8]];
        [jailbreakTool setToolTip:@"Click to visit the jailbreak tool website."];
    }
    if (data[9].length == 0) { [unlockTool setStringValue:@"X"]; }
    else { unlock_url = [NSString stringWithString:data[9]];
        [unlockTool setToolTip:@"Click to visit the unlock tool website."];
    }
    if (data[10].length == 0) { ipsw_url = nil; }
    else { ipsw_url = [NSString stringWithString:data[10]]; }
    if (data[11].length == 0) { ipswName = nil; }
    else { ipswName = [NSString stringWithString:data[11]]; }
    [startButton setEnabled:YES];
}

- (IBAction)toolButtonPressed:(id)sender {
    if (tool_url != Nil) {
        NSWorkspace * ws = [NSWorkspace sharedWorkspace];
        [ws openURL: [NSURL URLWithString:tool_url]];
    }
}

- (IBAction)unlockToolButtonPressed:(id)sender {
    if (unlock_url != Nil) {
        NSWorkspace * ws = [NSWorkspace sharedWorkspace];
        [ws openURL: [NSURL URLWithString:unlock_url]];
    }
}

- (IBAction)twitter1:(id)sender {
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    [ws openURL: [NSURL URLWithString:@"https://www.twitter.com/openIPSW"]];
}

- (IBAction)twitter2:(id)sender {
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    [ws openURL: [NSURL URLWithString:@"https://www.twitter.com/cs475x"]];
}

- (IBAction)twitter3:(id)sender {
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    [ws openURL: [NSURL URLWithString:@"https://www.twitter.com/themrzmaster"]];
}

- (IBAction)facebook:(id)sender {
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    [ws openURL: [NSURL URLWithString:@"https://www.facebook.com/openIPSW"]];
}

- (IBAction)github:(id)sender {
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    [ws openURL: [NSURL URLWithString:@"https://www.github.com/cs475x/openIPSW"]];
}

- (IBAction)homepage:(id)sender {
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    [ws openURL: [NSURL URLWithString:@"http://www.openIPSW.com"]];
}

- (id)init {
    [super init];
    networkQueue = [[ASINetworkQueue alloc] init];
    return self;
}

- (void)dealloc {
    [networkQueue release];
    [super dealloc];
}

- (IBAction)buttonPressed:(id)sender {
    if (ipswName == nil) {
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText: @"This firmware is unavailable for one of the following reasons:\n\n1. It is not available on Apple's servers.\n2. It is a premium update\n3. There is an error in our database"];
        [msgBox addButtonWithTitle: @"Okay"];
        [msgBox runModal];
    } else {
        [deviceBox setEnabled:false];
        [firmwareBox setEnabled:false];
        NSSavePanel *spanel = [NSSavePanel savePanel];
        [spanel setNameFieldStringValue:ipswName];
        [spanel setRequiredFileType:@"ipsw"];
        [spanel beginSheetForDirectory: @"~/Downloads/" file:nil modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSaveSheet:returnCode:conextInfo:) contextInfo:NULL];
    }
}

- (void)didEndSaveSheet:(NSSavePanel *)savePanel returnCode:(int)returnCode conextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        location = [savePanel filename];
        [self URLFetchWithProgress:self];
        [deviceBox setEnabled:false];
        [firmwareBox setEnabled:false];
    } else {
        [deviceBox setEnabled:true];
        [firmwareBox setEnabled:true];
    }
}


- (IBAction)URLFetchWithProgress:(id)sender {
    [deviceBox setEnabled:false];
    [firmwareBox setEnabled:false];
    [startButton setTitle:@"Cancel"];
    [startButton setAction:@selector(stopDownloading:)];
    [resumeButton setEnabled:true];
    NSString *tempFile = [location stringByAppendingPathExtension:@"download"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempFile]) {
        [[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
    }
    [self resumeURLFetchWithProgress:self];
}

- (IBAction)resumeURLFetchWithProgress:(id)sender {
    [resumeButton setTitle:@"Pause"];
    [resumeButton setAction:@selector(stopURLFetchWithProgress:)];
    [bandwidthUsed setHidden:false];
    [networkQueue reset];
    [self setBigFetchRequest:[ASIHTTPRequest requestWithURL:[NSURL URLWithString:ipsw_url]]];
    [[self bigFetchRequest] setDownloadDestinationPath:location];
    [[self bigFetchRequest] setTemporaryFileDownloadPath:[location stringByAppendingPathExtension:@"download"]];
    [[self bigFetchRequest] setAllowResumeForFileDownloads:YES];
    [[self bigFetchRequest] setDelegate:self];
    [[self bigFetchRequest] setDidFinishSelector:@selector(URLFetchWithProgressComplete:)];
    [[self bigFetchRequest] setDidFailSelector:@selector(URLFetchWithProgressFailed:)];
    [[self bigFetchRequest] setDownloadProgressDelegate:progressIndicator];
    [[self bigFetchRequest] startAsynchronous];
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateBandwidthUsageIndicator) userInfo:nil repeats:YES];
}

- (IBAction)stopURLFetchWithProgress:(id)sender {
    [resumeButton setTitle:@"Resume"];
    [resumeButton setAction:@selector(resumeURLFetchWithProgress:)];
    [[self bigFetchRequest] cancel];
    [self setBigFetchRequest:nil];
    [resumeButton setEnabled:YES];
    [bandwidthUsed setStringValue:@"Download Paused!"];
    if (updateTimer) {
        [updateTimer invalidate];
        updateTimer = nil;
    }
}

- (void)URLFetchWithProgressComplete:(ASIHTTPRequest *)request {
    [deviceBox setEnabled:true];
    [firmwareBox setEnabled:true];
    [progressIndicator setDoubleValue:0];
    [bandwidthUsed setHidden:true];
    [startButton setTitle:@"Download"];
    [startButton setAction:@selector(URLFetchWithProgress:)];
    location = nil;
    if (updateTimer) {
        [updateTimer invalidate];
        updateTimer = nil;
    }
    [window setTitle:@"openIPSW"];
    if (floor(NSAppKitVersionNumber) >= 1187) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        [notification setTitle:@"Download Complete!"];
        [notification setInformativeText:[NSString stringWithFormat:@"%@ for %@ has finished downloading", firmwareBox.objectValue, deviceBox.objectValue]];
        [notification setSoundName:NSUserNotificationDefaultSoundName];
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center scheduleNotification:notification];
    }
}

- (void)URLFetchWithProgressFailed:(ASIHTTPRequest *)request {
    if ([[request error] domain] == NetworkRequestErrorDomain && [[request error] code] == ASIRequestCancelledErrorType) {
    } else {
        [deviceBox setEnabled:true];
        [firmwareBox setEnabled:true];
        [progressIndicator setDoubleValue:0];
        [bandwidthUsed setHidden:true];
        [startButton setTitle:@"Download"];
        [startButton setAction:@selector(URLFetchWithProgress:)];
    }
}

- (void)stopDownloading:(ASIHTTPRequest *)request {
    [deviceBox setEnabled:true];
    [firmwareBox setEnabled:true];
    [resumeButton setEnabled:false];
    [progressIndicator setDoubleValue:0];
    [bandwidthUsed setHidden:true];
    [[self bigFetchRequest] cancel];
    [self setBigFetchRequest:nil];
    [startButton setTitle:@"Download"];
    [startButton setAction:@selector(buttonPressed:)];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@",[location stringByAppendingPathExtension:@"download"]] error:NULL];
    location = nil;
    if (updateTimer) {
        [updateTimer invalidate];
        updateTimer = nil;
    }
    [window setTitle:@"openIPSW"];
}

- (void)updateBandwidthUsageIndicator {
    NSString *yourPath = [location stringByAppendingPathExtension:@"download"];
    NSFileManager *man = [[NSFileManager alloc] init];
    NSDictionary *attrs = [man attributesOfItemAtPath: yourPath error: NULL];
    NSString *result = [NSString stringWithFormat:@"%f", (double)[attrs fileSize] / 1000000];
    NSString *fileSize = [NSString stringWithFormat:@"%@",[result substringWithRange:NSMakeRange(0, result.length - 4)]];
    [bandwidthUsed setStringValue:[NSString stringWithFormat:@"Download Speed: %luKB/s (%@ MB / %@)",[ASIHTTPRequest averageBandwidthUsedPerSecond]/1024, fileSize, infoSize.stringValue]];
    [man release];
    NSString *title = [NSString stringWithFormat:@"openIPSW (%@%%)", [[NSString stringWithFormat:@"%f",[progressIndicator doubleValue]] substringWithRange:NSMakeRange(2, 2)]];
    [window setTitle:title];
}

- (IBAction)throttleBandwidth:(id)sender {
    if ([(NSButton *)sender state] == NSOnState) {
        [ASIHTTPRequest setMaxBandwidthPerSecond: 51200];
    } else {
        [ASIHTTPRequest setMaxBandwidthPerSecond: 0];
    }
}

- (void)alertDidEnd:(NSAlert *)internetAlert returnCode:(int)alertButton contextInfo:(void *)context {
    switch (alertButton) {
        case NSAlertFirstButtonReturn:
            exit(0);
            break;
        default:
            break;
    }
}

- (void)checkInternet {
    //NSError *error;
    //NSString *URLString = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www.google.com"] encoding:NSUTF8StringEncoding error:&error];
    //if(URLString == nil) {
    //    NSAlert *internetAlert = [[[NSAlert alloc] init] autorelease];
    //    [internetAlert addButtonWithTitle:@"Close"];
    //    [internetAlert setMessageText:@"No internet connection!"];
    //    [internetAlert setInformativeText:@"openIPSW requires an internet connection to function.\n\nThis application will now exit."];
    //    [internetAlert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    //}
}

@end