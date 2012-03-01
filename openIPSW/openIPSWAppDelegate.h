#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface openIPSWAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    IBOutlet NSTextField *downloadInfo;
    IBOutlet NSTextField *jailbreakResult;
    IBOutlet NSButton *jailbreakTool;
    IBOutlet NSTextField *unlockResult;
    IBOutlet NSButton *unlockTool;
    IBOutlet NSTextField *infoSize;
    IBOutlet NSTextField *infoSHSH;
    IBOutlet NSTextField *infoBaseband;
    IBOutlet NSComboBox *deviceBox;
    IBOutlet NSComboBox *firmwareBox;
    ASINetworkQueue *networkQueue;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSButton *showAccurateProgress;
	IBOutlet NSButton *startButton;
	IBOutlet NSButton *resumeButton;
	IBOutlet NSTextField *bandwidthUsed;
    IBOutlet NSTextField *deviceLabel;
    IBOutlet NSTextField *firmwareLabel;
    IBOutlet NSBox *jailbreakBox;
    IBOutlet NSBox *unlockBox;
    IBOutlet NSBox *informationBox;
    IBOutlet NSTextField *jailbreakAvailable;
    IBOutlet NSTextField *jailbreakToolText;
    IBOutlet NSTextField *unlockAvailable;
    IBOutlet NSTextField *unlockToolText;
    IBOutlet NSTextField *shshText;
    IBOutlet NSTextField *sizeText;
    IBOutlet NSTextField *basebandText;
	ASIHTTPRequest *bigFetchRequest;
}

extern NSString * const sqlHost;
extern NSString * const sqlPort;
extern NSString * const sqlUser;
extern NSString * const sqlPass;
extern NSString * const sqlDB;

- (IBAction)buttonPressed:(id)sender;
- (IBAction)deviceChanged:(id)sender;
- (IBAction)firmwareSelected:(id)sender;
- (IBAction)URLFetchWithProgress:(id)sender;
- (IBAction)stopURLFetchWithProgress:(id)sender;
- (IBAction)resumeURLFetchWithProgress:(id)sender;
- (IBAction)throttleBandwidth:(id)sender;
- (IBAction)toolButtonPressed:(id)sender;
- (IBAction)unlockToolButtonPressed:(id)sender;
- (IBAction)twitter1:(id)sender;
- (IBAction)twitter2:(id)sender;
- (IBAction)twitter3:(id)sender;
- (IBAction)facebook:(id)sender;
- (IBAction)github:(id)sender;
- (IBAction)homepage:(id)sender;

@property (retain, nonatomic) ASIHTTPRequest *bigFetchRequest;
@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) NSButton *button;
@property (nonatomic, retain) NSTextField *jailbreakResult;
@property (nonatomic, retain) NSButton *jailbreakTool;
@property (nonatomic, retain) NSTextField *unlockResult;
@property (nonatomic, retain) NSButton *unlockTool;
@property (nonatomic, retain) NSTextField *infoSize;
@property (nonatomic, retain) NSTextField *infoSHSH;
@property (nonatomic, retain) NSTextField *infoBaseband;
@property (nonatomic, retain) NSComboBox *deviceBox;
@property (nonatomic, retain) NSComboBox *firmwareBox;

@end