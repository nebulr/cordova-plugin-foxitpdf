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

#import <Foundation/Foundation.h>

#import "UIExtensionsManager+Private.h"
#import <FoxitRDK/FSPDFViewControl.h>

@class NoteDialog;

typedef void (^NoteEditDone)(NoteDialog *);
typedef void (^NoteEditCancel)(NoteDialog *);
typedef void (^NoteEditDelete)(NoteDialog *);

/**@brief A note annotation dialog when being new added. */
@interface NoteDialog : UIViewController <UINavigationControllerDelegate, UITextViewDelegate> {
    CGRect _oldRect;
    NSTimer *_caretVisibilityTimer;
}

@property (nonatomic, copy) NoteEditDone noteEditDone;
@property (nonatomic, copy) NoteEditCancel noteEditCancel;
@property (nonatomic, copy) NoteEditDelete noteEditDelete;

- (void)show:(FSAnnot *)rootAnnot replyAnnots:(NSArray *)replyAnnots title:(NSString *)title;
- (void)dismiss;
- (NSString *)getContent;
@end
