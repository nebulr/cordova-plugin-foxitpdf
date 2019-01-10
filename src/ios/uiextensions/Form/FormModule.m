/**
 * Copyright (C) 2003-2018, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import "FormModule.h"
#import <FoxitRDK/FSPDFViewControl.h>

#import "../Common/UIExtensionsSharedHeader.h"
#import "FormAnnotHandler.h"
#import "Utility.h"

@interface FormModule () {
    FSPDFViewCtrl *__weak _pdfViewCtrl;
    UIExtensionsManager *__weak _extensionsManager;
}

@property (nonatomic, strong) MenuGroup *group;
@property (nonatomic, strong) MenuView *moreMenu;
@property (nonatomic, strong) MvMenuItem *exportFormItem;
@property (nonatomic, strong) MvMenuItem *importFormItem;
@property (nonatomic, strong) MvMenuItem *resetFormItem;

@end

@implementation FormModule

- (NSString *)getName {
    return @"Form";
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        [self loadModule];
        
        FormAnnotHandler* annotHandler = [[FormAnnotHandler alloc] initWithUIExtensionsManager:extensionsManager];
        [_extensionsManager registerAnnotHandler:annotHandler];
        [_extensionsManager registerRotateChangedListener:annotHandler];
        [_pdfViewCtrl registerDocEventListener:annotHandler];
    }
    return self;
}

- (void)loadModule {
    self.moreMenu = _extensionsManager.more;
    self.group = [self.moreMenu getGroup:TAG_GROUP_FORM];
    if (!self.group) {
        self.group = [[MenuGroup alloc] init];
        self.group.title = FSLocalizedString(@"kForm");
        self.group.tag = TAG_GROUP_FORM;
        [self.moreMenu addGroup:self.group];
    }
    self.exportFormItem = [[MvMenuItem alloc] init];
    self.exportFormItem.tag = TAG_ITEM_EXPORTFORM;
    self.exportFormItem.callBack = self;
    self.exportFormItem.text = FSLocalizedString(@"kExportForm");
    [self.moreMenu addMenuItem:self.group.tag withItem:self.exportFormItem];

    self.importFormItem = [[MvMenuItem alloc] init];
    self.importFormItem.tag = TAG_ITEM_IMPORTFORM;
    self.importFormItem.callBack = self;
    self.importFormItem.text = FSLocalizedString(@"kImportForm");
    [self.moreMenu addMenuItem:self.group.tag withItem:self.importFormItem];

    self.resetFormItem = [[MvMenuItem alloc] init];
    self.resetFormItem.tag = TAG_ITEM_RESETFORM;
    self.resetFormItem.callBack = self;
    self.resetFormItem.text = FSLocalizedString(@"kResetFormFields");
    [self.moreMenu addMenuItem:self.group.tag withItem:self.resetFormItem];
}

- (void)onClick:(MvMenuItem *)item {
    NSFileManager *filemanager = [NSFileManager defaultManager];
    _extensionsManager.hiddenMoreMenu = YES;

    if (![_pdfViewCtrl.currentDoc hasForm]) {
        AlertView *alertView = [[AlertView alloc] initWithTitle:nil message:@"kNoFormAvailable" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }

    BOOL canFillForm = [Utility canFillFormInDocument:_pdfViewCtrl.currentDoc];

    if (item.tag == TAG_ITEM_EXPORTFORM) {
        if (!canFillForm) {
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kRMSNoAccess" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }

        FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
        selectDestination.isRootFileDirectory = YES;
        selectDestination.fileOperatingMode = FileListMode_Select;
        [selectDestination loadFilesWithPath:DOCUMENT_PATH];
        selectDestination.operatingHandler = ^(FileSelectDestinationViewController *controller, NSArray *destinationFolder) {
            [controller dismissViewControllerAnimated:YES completion:nil];

            __block void (^inputFileName)(void) = ^() {
                InputAlertView *inputAlertView = [[InputAlertView alloc] initWithTitle:@"kInputNewFileName"
                                                                               message:nil
                                                                    buttonClickHandler:^(UIView *alertView, NSInteger buttonIndex) {
                                                                        if (buttonIndex == 0) {
                                                                            return;
                                                                        }
                                                                        InputAlertView *inputAlert = (InputAlertView *) alertView;
                                                                        NSString *fileName = inputAlert.inputTextField.text;

                                                                        if ([fileName rangeOfString:@"/"].location != NSNotFound) {
                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning"
                                                                                                                                message:@"kIllegalNameWarning"
                                                                                                                     buttonClickHandler:^(UIView *alertView, NSInteger buttonIndex) {
                                                                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                             inputFileName();
                                                                                                                         });
                                                                                                                         return;
                                                                                                                     }
                                                                                                                      cancelButtonTitle:@"kOK"
                                                                                                                      otherButtonTitles:nil];
                                                                                [alertView show];
                                                                            });
                                                                            return;
                                                                        } else if (fileName.length == 0) {
                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                inputFileName();
                                                                            });
                                                                            return;
                                                                        }

                                                                        void (^createXML)(NSString *xmlFilePath) = ^(NSString *xmlFilePath) {
                                                                            NSString *tmpFilePath = [TEMP_PATH stringByAppendingPathComponent:[xmlFilePath lastPathComponent]];
                                                                            FSForm *form = [_pdfViewCtrl.currentDoc getForm];
                                                                            if (nil == form)
                                                                                return;

                                                                            BOOL isSuccess = NO;
                                                                            @try {
                                                                                isSuccess = [form exportToXML:tmpFilePath];
                                                                            } @catch (NSException *exception) {
                                                                                NSLog(@"ExportToXML EXCEPTION NAME:%@", exception.name);
                                                                            }

                                                                            if (isSuccess) {
                                                                                double delayInSeconds = 0.4;
                                                                                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {

                                                                                    AlertView *alertView = [[AlertView alloc] initWithTitle:@"" message:@"kExportFormSuccess" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
                                                                                    [alertView show];
                                                                                    [filemanager moveItemAtPath:tmpFilePath toPath:xmlFilePath error:nil];
                                                                                });
                                                                            } else {
                                                                                double delayInSeconds = 0.4;
                                                                                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                                                                    AlertView *alertView = [[AlertView alloc] initWithTitle:@"" message:@"kExportFormFailed" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
                                                                                    [alertView show];
                                                                                });
                                                                            }

                                                                        };

                                                                        NSString *xmlFilePath = [destinationFolder[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml", fileName]];
                                                                        NSFileManager *fileManager = [[NSFileManager alloc] init];
                                                                        if ([fileManager fileExistsAtPath:xmlFilePath]) {
                                                                            double delayInSeconds = 0.3;
                                                                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                                                                                AlertView *alert = [[AlertView alloc] initWithTitle:@"kWarning"
                                                                                                                            message:@"kFileAlreadyExists"
                                                                                                                 buttonClickHandler:^(UIView *alertView, NSInteger buttonIndex) {
                                                                                                                     if (buttonIndex == 0) {
                                                                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                             inputFileName();
                                                                                                                         });
                                                                                                                     } else {
                                                                                                                         inputFileName = nil;
                                                                                                                         [fileManager removeItemAtPath:xmlFilePath error:nil];
                                                                                                                         createXML(xmlFilePath);
                                                                                                                     }
                                                                                                                 }
                                                                                                                  cancelButtonTitle:@"kCancel"
                                                                                                                  otherButtonTitles:@"kReplace", nil];
                                                                                [alert show];
                                                                            });
                                                                        } else {
                                                                            inputFileName = nil;
                                                                            createXML(xmlFilePath);
                                                                        }
                                                                    }
                                                                     cancelButtonTitle:@"kCancel"
                                                                     otherButtonTitles:@"kOK", nil];
                inputAlertView.style = TSAlertViewStyleInputText;
                inputAlertView.buttonLayout = TSAlertViewButtonLayoutNormal;
                inputAlertView.usesMessageTextView = NO;
                [inputAlertView show];
            };

            inputFileName();
        };
        selectDestination.cancelHandler = ^(FileSelectDestinationViewController *controller) {
            [controller dismissViewControllerAnimated:YES completion:nil];
        };
        UINavigationController *selectDestinationNavController = [[UINavigationController alloc] initWithRootViewController:selectDestination];
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootViewController presentViewController:selectDestinationNavController
                                         animated:YES
                                       completion:nil];
    } else if (item.tag == TAG_ITEM_IMPORTFORM) {
        if (!canFillForm) {
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kRMSNoAccess" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }

        FileSelectDestinationViewController *selectDestination = [[FileSelectDestinationViewController alloc] init];
        selectDestination.isRootFileDirectory = YES;
        selectDestination.fileOperatingMode = FileListMode_Import;
        selectDestination.expectFileType = [NSArray arrayWithObject:@"xml"];
        [selectDestination loadFilesWithPath:DOCUMENT_PATH];

        selectDestination.operatingHandler = ^(FileSelectDestinationViewController *controller, NSArray *destinationFolder) {
            [controller dismissViewControllerAnimated:YES completion:nil];
            if (destinationFolder.count > 0) {
                FSForm *form = [_pdfViewCtrl.currentDoc getForm];
                if (nil == form)
                    return;
                BOOL isSuccess = NO;
                @try {
                    isSuccess = [form importFromXML:destinationFolder[0]];
                } @catch (NSException *exception) {
                    NSLog(@"ImportFromXML EXCEPTION NAME:%@", exception.name);
                }
                if (isSuccess) {
                    double delayInSeconds = 0.3;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                        AlertView *alertView = [[AlertView alloc] initWithTitle:@"" message:@"kImportFormSuccess" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
                        [alertView show];
                    });
                } else {
                    double delayInSeconds = 0.3;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                        AlertView *alertView = [[AlertView alloc] initWithTitle:@"" message:@"kImportFormFailed" buttonClickHandler:nil cancelButtonTitle:nil otherButtonTitles:@"kOK", nil];
                        [alertView show];
                    });
                }
            }
        };
        selectDestination.cancelHandler = ^(FileSelectDestinationViewController *controller) {
            [controller dismissViewControllerAnimated:YES completion:nil];
        };
        UINavigationController *selectDestinationNavController = [[UINavigationController alloc] initWithRootViewController:selectDestination];
        [_pdfViewCtrl.window.rootViewController presentViewController:selectDestinationNavController animated:YES completion:nil];
    } else if (item.tag == TAG_ITEM_RESETFORM) {
        if (!canFillForm) {
            AlertView *alertView = [[AlertView alloc] initWithTitle:@"kWarning" message:@"kRMSNoAccess" buttonClickHandler:nil cancelButtonTitle:@"kOK" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }

        AlertView *alertView = [[AlertView alloc] initWithTitle:@"kConfirm"
                                                        message:@"kSureToResetFormFields"
                                             buttonClickHandler:^(UIView *alertView, NSInteger buttonIndex) {
                                                 if (buttonIndex == 1) {
                                                     FSForm *form = [_pdfViewCtrl.currentDoc getForm];
                                                     if (nil == form)
                                                         return;
                                                     [form reset];
                                                     [_extensionsManager clearThumbnailCachesForPDFAtPath:_pdfViewCtrl.filePath];
                                                 }
                                             }
                                              cancelButtonTitle:@"kNo"
                                              otherButtonTitles:@"kYes", nil];
        [alertView show];
    }
}

@end
