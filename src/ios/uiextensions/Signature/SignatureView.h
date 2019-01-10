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

#import <UIKit/UIKit.h>

#import <FoxitRDK/FSPDFViewControl.h>

@interface SignatureView : UIView {
    void *dibBuf;
}

@property (nonatomic, strong) FSBitmap *dib;
@property (nonatomic, assign) CGRect rectSigPart;
@property (nonatomic, assign) int color;
@property (nonatomic, assign) int diameter;
@property (nonatomic, assign) BOOL hasChanged;
@property (nonatomic, copy) void (^signHasChangedCallback)(BOOL hasChanged);

- (void)clear;
- (void)loadSignature:(NSData *)dibData rect:(CGRect)rect;
- (UIImage *)getCurrentImage;
- (NSData *)getCurrentDib;
- (void)invalidateRect:(FSRectF *)rect;
@end

@interface FSPSICallbackImp : FSPSICallback

@property (nonatomic, weak) SignatureView *sigView;

- (id)initWithSigView:(SignatureView *)view;

@end
