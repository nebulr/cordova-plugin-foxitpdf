/********* FoxitPdf.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

#import <FoxitRDK/FSPDFViewControl.h>
#import "uiextensions/UIExtensionsManager.h"

NSString *SN = @"XFasGJlbJhCyuCChjvaTZhYP48qPbcH6CHKVOYaOMp6ff7qkKsMTKQ==";
NSString *UNLOCK = @"ezJvj90ntWp39JsXIV02hAkoHz2UIaApLY/TASnOq+HvnZAr455g+dgZ2rOwKqV3ji1R8nd+zUhrSSnmokSzw9EiWGPd1WjDHKOTA/eqNb+4n5zcXXqsucfMI6fOsUQoiZYtHVOR760n3eCrIP1sOQKBEEMJ0iwoh2SpQYfdZEL186cLa60q0+u/8ztlgKvzHEnnIf5tFYoF5Q1IVdhzzjG4Vry8r6tGiFXZTcD050OHhMpShd/7MfoFseG65Yyqnuum074i2w1DAKZI67ZKX0H1Dex9kvWfF1m/UUl4qz7beMBQ5IEmDwScpmLwLmyw1IR5xlRQ8sMr+Z5MpyXGpHvbzJa50mSsl9bS5cf4ctgNo7C+/Yt+U4ODtd8Ax+txSXbf71Qa+FaTDi2jrdQLlSo+8DUchEDIm4g35IC0RrdBSeMhI094ZxFbTRAHwgPoDXbc2fyaYtKRFFNjN9Yu/651D9zaZdOiDwWeeozGb2dF94ICk+JqsJuX8Epxh1Jhvst5PrNAgBI6e27t+vxsmx1vrwR6HtN5hY4BqWNF1PBP4AzvYJutiJ4/ZeJ7sbLRf8ERf9OVeobIjxY2SPgy62nF4Lckk/eG9lZsWyM2TlRn4lSEYRLVCmhMT7x+aqXkVCNVISilf/MhlNl1psxaKpWGXLrkVbTTrXoFQPUeSHLcd2KPFFUo6gAEMEjkOyklFCvnGj8wKIw1I3UCzuUsc5Qv49C+mR5wOpJt9v9OUbj3p7+HTGZpF4RY3B3rJkgsv3yWYG2M7orgrmGE4vF9cgWv42phioU0pw/oKwatsn4Me4sp7W6i6mdAQnS5ehDqqJpFWQY7j9HO60RGz9VXQzVrKLr5g4sGOx3GYk/LZnneWTllDtbm78tqSYvZjH4+zY6ZiqHdWCFKS6lNQVKVFgT8daeTS9iC+6D7CMRK9DARlaACFIhmo2pAXDaCJFuuQawRirQON3eqiBkSvanyMpUDpSrvW8V64DI0gA21CR0PQmRYeDcGuhw96F8VywZW5apPttBmmPXvi05j068zTJ1kHqqAYhGk07wKxhVZJ8Xy5oG4dBhfgqpUOsYeGE88FQxUcJ3YhsSpZ0Sbo9Xo3Arr1n1uH0Wfal2Vt0PGckP/4WbPhAWZWsOo8mjY8LhqOTd+Ii2PVANrHvLzfBh8er2b2TTPrxoaeqIljOGEX2Es6RBfJq9B9urx+ihzpY6qP9+T+kM=";

@interface FoxitPdf : CDVPlugin <IDocEventListener>{
    // Member variables go here.
}
@property (nonatomic, strong) NSArray *topToolbarVerticalConstraints;
@property (nonatomic, strong) UIExtensionsManager *extensionsMgr;
@property (nonatomic, strong) FSPDFViewCtrl *pdfViewControl;
@property (nonatomic, strong) UIViewController *pdfViewController;

@property (nonatomic, strong) CDVInvokedUrlCommand *pluginCommand;

@property (nonatomic, strong) NSString *filePathSaveTo;
@property (nonatomic, strong) NSString *docDir;
@property (nonatomic, strong) NSString *input;
@property (nonatomic, strong) NSString *output;
@property (nonatomic, strong) FSFDFDoc *annotations;

- (void)Preview:(CDVInvokedUrlCommand *)command;
@end

@implementation FoxitPdf
{
    NSString *tmpCommandCallbackID;
}

- (void)Preview:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *pluginResult = nil;
    self.pluginCommand = command;
    
    self.docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSLog(@"%@", self.docDir);
    
    self.input = [NSString stringWithFormat:@"%@%@", self.docDir, @"/input.xfdf"];
    self.output = [NSString stringWithFormat:@"%@%@", self.docDir, @"/output.xfdf"];
    
    NSDictionary* options = [command argumentAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
    NSString *jsfilePathSaveTo = [options objectForKey:@"filePathSaveTo"];
    if (jsfilePathSaveTo && jsfilePathSaveTo.length >0 ) {
        NSURL *filePathSaveTo = [[NSURL alloc] initWithString:jsfilePathSaveTo];
        self.filePathSaveTo = filePathSaveTo.path;
    }else{
        self.filePathSaveTo  = nil;
    }
    
    // URL
    //    NSString *filePath = [command.arguments objectAtIndex:0];
    NSString *filePath = [options objectForKey:@"filePath"];
    NSString *annotations = [options objectForKey:@"annotations"];
    
    // check file exist
    NSURL *fileURL = [[NSURL alloc] initWithString:filePath];
    BOOL isFileExist = [self isExistAtPath:fileURL.path];
    
    if (filePath != nil && filePath.length > 0  && isFileExist) {
        //NSData *annots;
        if (annotations != [NSNull null]) {
            [annotations stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
            NSError *error;
            [annotations writeToFile:self.input atomically:YES encoding:NSUTF8StringEncoding error:&error];
        }
        
        // preview
        [self FoxitPdfPreview:fileURL.path];
        
        // result object
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"preview success"];
        tmpCommandCallbackID = command.callbackId;
    } else {
        NSString* errMsg = [NSString stringWithFormat:@"file not find"];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR  messageAsString:@"file not found"];
    }
    
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

# pragma mark -- Foxit preview
-(void)FoxitPdfPreview:(NSString *)filePath {
    // init foxit sdk
    FSErrorCode eRet = [FSLibrary init:SN key:UNLOCK];
    if (e_errSuccess != eRet) {
        NSString* errMsg = [NSString stringWithFormat:@"Invalid license"];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Check License" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    self.annotations = [[FSFDFDoc alloc] initWithFilePath:self.input];
    self.pdfViewControl = [[FSPDFViewCtrl alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.pdfViewControl registerDocEventListener:self];
    
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"uiextensions_config" ofType:@"json"];
    self.extensionsMgr = [[UIExtensionsManager alloc] initWithPDFViewControl:self.pdfViewControl configuration:[NSData dataWithContentsOfFile:configPath]];
    self.pdfViewControl.extensionsManager = self.extensionsMgr;
    self.extensionsMgr.delegate = self;
    
    //load doc
    if (filePath == nil) {
        filePath = [[NSBundle mainBundle] pathForResource:@"getting_started_ios" ofType:@"pdf"];
    }
    
    if (e_errSuccess != eRet) {
        NSString *errMsg = [NSString stringWithFormat:@"Invalid license"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check License" message:errMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    self.pdfViewController = [[UIViewController alloc] init];
    self.pdfViewController.view = self.pdfViewControl;
    
    if(self.filePathSaveTo && self.filePathSaveTo.length >0){
        self.extensionsMgr.preventOverrideFilePath = self.filePathSaveTo;
    }
    
    [self.pdfViewControl openDoc:filePath
                        password:nil
                      completion:^(FSErrorCode error) {
                          if (error != e_errSuccess) {
                              UIAlertView *alert = [[UIAlertView alloc]
                                                    initWithTitle:@"error"
                                                    message:@"Failed to open the document"
                                                    delegate:nil
                                                    cancelButtonTitle:nil
                                                    otherButtonTitles:@"ok", nil];
                              [alert show];
                          }
                      }];
    
    __weak FoxitPdf* weakSelf = self;
    self.pdfViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.viewController presentViewController:self.pdfViewController animated:YES completion:nil];
    });
    
    [self wrapTopToolbar];
    self.topToolbarVerticalConstraints = @[];
    
    self.extensionsMgr.goBack = ^() {
        [weakSelf.viewController dismissViewControllerAnimated:YES completion:nil];
    };
}

#pragma mark <IDocEventListener>

- (void)onDocOpened:(FSPDFDoc *)document error:(int)error {
    // Called when a document is opened.
    // Get any annotations if they exist then add them the pdfViewControl PDF Doc
    if (self.annotations != [NSNull null]) {
        [self.annotations exportAllAnnotsToPDFDoc:document];
    }
    
    [self.pdfViewControl setPageLayoutMode:PDF_LAYOUT_MODE_CONTINUOUS];
    
}

- (void)onDocClosed:(FSPDFDoc *)document error:(int)error {
    // Called when a document is closed.
    FSFDFDoc *annots = [[FSFDFDoc alloc] initWithFDFDocType:1];
    [annots importAllAnnotsFromPDFDoc:[self.pdfViewControl getDoc]];
    [annots saveAs:self.output];
    NSString *stringContent = [NSString stringWithContentsOfFile:self.output encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@", stringContent);
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:@{@"type":@"onDocClosed", @"info":stringContent}];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.pluginCommand.callbackId];
}

- (void)onDocSaved:(FSPDFDoc *)document error:(int)error{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:@{@"type":@"onDocSaved", @"info":@"info"}];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.pluginCommand.callbackId];
}

# pragma mark -- isExistAtPath
- (BOOL)isExistAtPath:(NSString *)filePath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:filePath];
    return isExist;
}

#pragma mark <UIExtensionsManagerDelegate>
- (void)uiextensionsManager:(UIExtensionsManager *)uiextensionsManager setTopToolBarHidden:(BOOL)hidden {
    UIToolbar *topToolbar = self.extensionsMgr.topToolbar;
    UIView *topToolbarWrapper = topToolbar.superview;
    id topGuide = self.pdfViewController.topLayoutGuide;
    assert(topGuide);
    
    [self.pdfViewControl removeConstraints:self.topToolbarVerticalConstraints];
    if (!hidden) {
        NSMutableArray *contraints = @[].mutableCopy;
        [contraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-0-[topToolbar(44)]"
                                                 options:0
                                                 metrics:nil
                                                   views:NSDictionaryOfVariableBindings(topToolbar, topGuide)]];
        [contraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topToolbarWrapper]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(topToolbarWrapper)]];
        self.topToolbarVerticalConstraints = contraints;
        
    } else {
        self.topToolbarVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[topToolbarWrapper]-0-[topGuide]"
                                                                                     options:0
                                                                                     metrics:nil
                                                                                       views:NSDictionaryOfVariableBindings(topToolbarWrapper, topGuide)];
    }
    [self.pdfViewControl addConstraints:self.topToolbarVerticalConstraints];
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self.pdfViewControl layoutIfNeeded];
                     }];
}

- (void)wrapTopToolbar {
    // let status bar be translucent. top toolbar is top layout guide (below status bar), so we need a wrapper to cover the status bar.
    UIToolbar *topToolbar = self.extensionsMgr.topToolbar;
    [topToolbar setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    UIView *topToolbarWrapper = [[UIToolbar alloc] init];
    [topToolbarWrapper setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.pdfViewControl insertSubview:topToolbarWrapper belowSubview:topToolbar];
    [topToolbarWrapper addSubview:topToolbar];
    
    [self.pdfViewControl addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[topToolbarWrapper]-0-|"
                                             options:0
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(topToolbarWrapper)]];
    [topToolbarWrapper addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[topToolbar]-0-|"
                                             options:0
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(topToolbar)]];
    [topToolbarWrapper addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:[topToolbar]-0-|"
                                             options:0
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(topToolbar)]];
}
@end
