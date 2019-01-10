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

#import "TextboxToolHandler.h"
#import "ColorUtility.h"
#import "Masonry.h"
#import "StringDrawUtil.h"
#import "UIExtensionsManager+Private.h"
#import "Utility.h"

@interface TextboxToolHandler () <UITextViewDelegate>

@property (nonatomic, assign) int pageIndex;
@property (nonatomic, assign) CGPoint tapPoint;
@property (nonatomic, assign) BOOL pageIsAlreadyExist;
@property (nonatomic, assign) int pageindex;
@property (nonatomic, strong) FSPointF *startPoint;
@property (nonatomic, strong) FSPointF *endPoint;
@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) FSRectF *dibRect;

@property (nonatomic, assign) int startPosIndex;
@property (nonatomic, assign) int endPosIndex;
@property (nonatomic, strong) NSArray *arraySelectedRect;
@property (nonatomic, assign) CGRect currentEditRect;
@property (nonatomic, assign) BOOL isPanCreate;
@end

@implementation TextboxToolHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
    TaskServer *_taskServer;
    CGFloat minAnnotPageInset;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _taskServer = _extensionsManager.taskServer;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanges:) name:UIDeviceOrientationDidChangeNotification object:nil];
        //        self.fontName = @"Times-Roman";
        //        self.fontSize = 12;
        _pageIsAlreadyExist = NO;
        _type = e_annotFreeText;
        minAnnotPageInset = 5;
    }
    return self;
}

- (NSString *)getName {
    return Tool_Textbox;
}

- (BOOL)isEnabled {
    return YES;
}

- (void)onActivate {
}

- (void)onDeactivate {
    [self save];
}

// PageView Gesture+Touch
- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer {
    if (!self.pageIsAlreadyExist) {
        self.pageIndex = pageIndex;
        self.pageIsAlreadyExist = YES;
    }
    [self save];
    _isSaved = NO;

    if (_extensionsManager.currentToolHandler == self) {
        CGPoint point = CGPointZero;
        UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
        if (recognizer) {
            point = [recognizer locationInView:pageView];
            //self.tapPoint = [recognizer locationInView:];

        } else {
            point = _freeTextStartPoint;
        }
        float fontSize = [_extensionsManager getAnnotFontSize:e_annotFreeText];
        fontSize = [Utility convertWidth:fontSize fromPageViewToPDF:_pdfViewCtrl pageIndex:pageIndex];
        NSString *fontName = [_extensionsManager getAnnotFontName:e_annotFreeText];
        UIFont *font = [self getSysFont:fontName size:fontSize];
        if (!font) {
            font = [UIFont boldSystemFontOfSize:fontSize];
        }
        CGSize testSize = [Utility getTestSize:font];
        _originalDibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];

        CGFloat pageViewWidth = [_pdfViewCtrl getPageView:pageIndex].frame.size.width;
        if(DEVICE_iPAD)
            _textView = [[UITextView alloc] initWithFrame:CGRectMake(point.x, point.y, pageViewWidth - point.x >= 300 ? 300 : pageViewWidth - point.x, testSize.height)];
        else
           _textView = [[UITextView alloc] initWithFrame:CGRectMake(point.x, point.y, pageViewWidth - point.x >= 100 ? 100 : pageViewWidth - point.x, testSize.height)];
        _textView.delegate = self;
        [self adjustTextViewFrame:_textView inPageView:pageView forMinPageInset:minAnnotPageInset];

        if ((DEVICE_iPHONE && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)) || (DEVICE_iPHONE && ((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) < (375 * 667)) && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight))) {
            UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
            doneView.backgroundColor = [UIColor clearColor];
            // doneView.backgroundColor = [UIColor colorWithRGBHex:0xfffbdb];
            UIButton *doneBT = [UIButton buttonWithType:UIButtonTypeCustom];
            [doneBT setBackgroundImage:[UIImage imageNamed:@"common_keyboard_done"] forState:UIControlStateNormal];
            [doneBT addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
            [doneView addSubview:doneBT];
            [doneBT mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(doneView.mas_right).offset(0);
                make.top.equalTo(doneView.mas_top).offset(0);
                make.size.mas_equalTo(CGSizeMake(40, 40));
            }];
            _textView.inputAccessoryView = doneView;
        }
        if (OS_ISVERSION7) {
            _textView.textContainerInset = UIEdgeInsetsMake(2, -4, 2, -4);
        } else {
            _textView.contentInset = UIEdgeInsetsMake(-8, -8, -8, -8);
        }
        _textView.layer.borderColor = [UIColor redColor].CGColor;
        _textView.layer.borderWidth = 1;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.textColor = ({
            UInt32 color = [_extensionsManager getAnnotColor:e_annotFreeText];
            float opacity = [_extensionsManager getAnnotOpacity:e_annotFreeText];
            BOOL isMappingColorMode = (_pdfViewCtrl.colorMode == e_colorModeMapping);
            if (isMappingColorMode && color == 0) {
                color = 16775930;
            }
            if (!isMappingColorMode && color == 16775930) {
                color = 0;
            }
            [UIColor colorWithRGBHex:color alpha:opacity];
        });
        _textView.font = font;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.showsHorizontalScrollIndicator = NO;
        _textView.scrollEnabled = NO;
        _textView.clipsToBounds = NO;
        [pageView addSubview:_textView];

        UIMenuController *menu = [UIMenuController sharedMenuController];
        menu.menuItems = nil;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasHidden:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];

        [_textView becomeFirstResponder];
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer {
    return [self onPageViewLongAndPan:pageIndex recognizer:recognizer];
}

- (BOOL)onPageViewLongAndPan:(int)pageIndex recognizer:(UIGestureRecognizer *)recognizer {
    id<IAnnotHandler> annotHandler = nil;
    FSAnnot *annot = _extensionsManager.currentAnnot;
    if (annot != nil) {
        annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            if ([annotHandler onPageViewShouldBegin:pageIndex recognizer:recognizer annot:annot]) {
                [annotHandler onPageViewPan:pageIndex recognizer:(UIPanGestureRecognizer*)recognizer annot:annot];
                return YES;
            } else {
                _extensionsManager.currentAnnot = nil;
            }
        } else {
            [annotHandler onPageViewPan:pageIndex recognizer:(UIPanGestureRecognizer*)recognizer annot:annot];
            return YES;
        }
    }
    UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
    CGPoint point = [recognizer locationInView:pageView];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self save];
        self.pageIndex = pageIndex;
        self.startPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (pageIndex != self.pageIndex) {
            return NO;
        }

        self.endPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        self.dibRect = [Utility convertToFSRect:self.startPoint p2:self.endPoint];
        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.dibRect pageIndex:pageIndex];
        rect = CGRectIntersection(rect, pageView.bounds);
        [_pdfViewCtrl refresh:CGRectUnion(rect, self.rect) pageIndex:pageIndex needRender:NO];
        self.rect = rect;

    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (pageIndex != self.pageIndex) {
            pageIndex = self.pageIndex;
            pageView = [_pdfViewCtrl getPageView:pageIndex];
            point = [recognizer locationInView:pageView];
        }
        NSMutableArray *arrayQuads = [NSMutableArray array];
        for (int i = 0; i < 1; i++) {
            CGPoint point1;
            CGPoint point2;
            CGPoint point3;
            CGPoint point4;
            point1.x = self.dibRect.left;
            point1.y = self.dibRect.top;
            point2.x = self.dibRect.right;
            point2.y = self.dibRect.top;
            point3.x = self.dibRect.left;
            point3.y = self.dibRect.bottom;
            point4.x = self.dibRect.right;
            point4.y = self.dibRect.bottom;

            NSValue *value1 = [NSValue valueWithCGPoint:point1];
            NSValue *value2 = [NSValue valueWithCGPoint:point2];
            NSValue *value3 = [NSValue valueWithCGPoint:point3];
            NSValue *value4 = [NSValue valueWithCGPoint:point4];
            NSArray *arrayQuad = [NSArray arrayWithObjects:value1, value2, value3, value4, nil];
            [arrayQuads addObject:arrayQuad];
        }
        if (!self.pageIsAlreadyExist) {
            self.pageIndex = pageIndex;
            self.pageIsAlreadyExist = YES;
        }

        CGRect rect = self.rect;
        [self save];
        _isSaved = NO;
        self.rect = rect;

        if (_extensionsManager.currentToolHandler == self) {
            float fontSize = [_extensionsManager getAnnotFontSize:e_annotFreeText];
            fontSize = [Utility convertWidth:fontSize fromPageViewToPDF:_pdfViewCtrl pageIndex:pageIndex];
            NSString *fontName = [_extensionsManager getAnnotFontName:e_annotFreeText];
            UIFont *font = [self getSysFont:fontName size:fontSize];
            if (!font) {
                font = [UIFont boldSystemFontOfSize:fontSize];
            }
            _originalDibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
            _textView = [[UITextView alloc] initWithFrame:CGRectMake(self.rect.origin.x, self.rect.origin.y, self.rect.size.width, self.rect.size.height)];

            if ((DEVICE_iPHONE && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)) || (DEVICE_iPHONE && ((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) < (375 * 667)) && ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight))) {
                UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
                doneView.backgroundColor = [UIColor clearColor];
                UIButton *doneBT = [UIButton buttonWithType:UIButtonTypeCustom];
                [doneBT setBackgroundImage:[UIImage imageNamed:@"common_keyboard_done"] forState:UIControlStateNormal];
                [doneBT addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
                [doneView addSubview:doneBT];
                [doneBT mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(doneView.mas_right).offset(0);
                    make.top.equalTo(doneView.mas_top).offset(0);
                    make.size.mas_equalTo(CGSizeMake(40, 40));
                }];
                _textView.inputAccessoryView = doneView;
            }
            _textView.delegate = self;
            if (OS_ISVERSION7) {
                _textView.textContainerInset = UIEdgeInsetsMake(2, -4, 2, -4);
            } else {
                _textView.contentInset = UIEdgeInsetsMake(-8, -8, -8, -8);
            }
            _textView.layer.borderColor = [UIColor redColor].CGColor;
            _textView.layer.borderWidth = 1;
            _textView.backgroundColor = [UIColor clearColor];
            _textView.textColor = ({
                UInt32 color = [_extensionsManager getAnnotColor:e_annotFreeText];
                float opacity = [_extensionsManager getAnnotOpacity:e_annotFreeText];
                BOOL isMappingColorMode = (_pdfViewCtrl.colorMode == e_colorModeMapping);
                if (isMappingColorMode && color == 0) {
                    color = 16775930;
                }
                if (!isMappingColorMode && color == 16775930) {
                    color = 0;
                }
                [UIColor colorWithRGBHex:color alpha:opacity];
            });
            _textView.font = font;
            _textView.showsVerticalScrollIndicator = NO;
            _textView.showsHorizontalScrollIndicator = NO;
            _textView.scrollEnabled = NO;
            _textView.clipsToBounds = NO;
            [_pdfViewCtrl refresh:_textView.frame pageIndex:pageIndex needRender:NO];

            [pageView addSubview:_textView];
            self.isPanCreate = YES;
            UIMenuController *menu = [UIMenuController sharedMenuController];
            menu.menuItems = nil;

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(keyboardWasShown:)
                                                         name:UIKeyboardDidShowNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(keyboardWasHidden:)
                                                         name:UIKeyboardWillHideNotification
                                                       object:nil];

            [_textView becomeFirstResponder];
            return YES;
        }
        return NO;
    }
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (_extensionsManager.currentToolHandler == self) {
        if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            if (_textView) {
                UIView *pageView = [_pdfViewCtrl getPageView:pageIndex];
                CGPoint point = [gestureRecognizer locationInView:pageView];
                if (_textView == [pageView hitTest:point withEvent:nil]) {
                    return NO;
                }
            }

            return YES; //Tap gesture to add free text by simple click
        }
    }
    return NO;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event {
    return NO;
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context {
    if (_extensionsManager.currentToolHandler != self) {
        return;
    }
    if (_textView) {
    } else {
        CGRect selfRect = self.rect;
        CGContextSetRGBFillColor(context, 0, 0, 1, 0.3);
        CGContextFillRect(context, selfRect);
    }
}

- (UIFont *)getSysFont:(NSString *)name size:(float)size {
    UIFont *font = [UIFont fontWithName:[Utility convert2SysFontString:name] size:size];
    if (!font) {
        font = [UIFont systemFontOfSize:size];
    }
    return font;
}

#pragma mark IDvTouchEventListener
- (void)onScrollViewWillBeginZooming:(UIScrollView *)scrollView {
    [self save];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    UIView *pageView = [_pdfViewCtrl getPageView:self.pageIndex];
    if (pageView) {
        CGRect frame = textView.frame;
        CGSize constraintSize = CGSizeMake(frame.size.width, MAXFLOAT);
        CGSize size = [textView sizeThatFits:constraintSize];
        if (self.isPanCreate) {
            if (size.height < frame.size.height) {
                size.height = frame.size.height;
            }
        }

        textView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, size.height);
        if (textView.frame.size.height >= (CGRectGetHeight(pageView.frame) - 20)) {
            [textView endEditing:YES];
        }
        if (textView.frame.size.width >= (CGRectGetWidth(pageView.frame) - 20)) {
            [textView endEditing:YES];
        }
        [self adjustTextViewFrame:textView inPageView:pageView forMinPageInset:minAnnotPageInset];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self save];
}

- (void)adjustTextViewFrame:(UITextView *)textView inPageView:(UIView *)pageView forMinPageInset:(CGFloat)inset {
    CGRect bounds = CGRectInset(pageView.bounds, inset, inset);
    if (!CGRectIntersectsRect(textView.frame, bounds)) {
        return;
    }
    if (CGRectGetMinX(textView.frame) < CGRectGetMinX(bounds)) {
        CGPoint center = textView.center;
        center.x += CGRectGetMinX(bounds) - CGRectGetMinX(textView.frame);
        textView.center = center;
    }
    if (CGRectGetMaxX(textView.frame) > CGRectGetMaxX(bounds)) {
        CGPoint center = textView.center;
        center.x -= CGRectGetMaxX(textView.frame) - CGRectGetMaxX(bounds);
        textView.center = center;
    }
    if (CGRectGetMinY(textView.frame) < CGRectGetMinY(bounds)) {
        CGPoint center = textView.center;
        center.y += CGRectGetMinY(bounds) - CGRectGetMinY(textView.frame);
        textView.center = center;
    }
    if (CGRectGetMaxY(textView.frame) > CGRectGetMaxY(bounds)) {
        CGPoint center = textView.center;
        center.y -= CGRectGetMaxY(textView.frame) - CGRectGetMaxY(bounds);
        textView.center = center;
    }
}

#pragma mark - keyboard
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)keyboardWasShown:(NSNotification *)aNotification {
    if (_keyboardShown) {
        return;
    }
    _keyboardShown = YES;
    NSDictionary *info = [aNotification userInfo];
    NSValue *frame = nil;
    frame = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGRect keyboardFrame = [frame CGRectValue];
    CGRect textFrame = _textView.frame;

    CGPoint oldPvPoint = [_pdfViewCtrl convertDisplayViewPtToPageViewPt:CGPointMake(0, 0) pageIndex:self.pageIndex];
    FSPointF *oldPdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:oldPvPoint pageIndex:self.pageIndex];

    CGRect dvAnnotRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:textFrame pageIndex:self.pageIndex];
    float positionY;
    if (DEVICE_iPHONE && !OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        positionY = SCREENWIDTH - dvAnnotRect.origin.y - dvAnnotRect.size.height;
    } else {
        positionY = SCREENHEIGHT - dvAnnotRect.origin.y - dvAnnotRect.size.height;
    }

    if (positionY < keyboardFrame.size.height) {
        float dvOffsetY = keyboardFrame.size.height - positionY + 40;
        CGRect offsetRect = CGRectMake(0, 0, 100, dvOffsetY);

        CGRect pvRect = [_pdfViewCtrl convertDisplayViewRectToPageViewRect:offsetRect pageIndex:self.pageIndex];
        FSRectF *pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:self.pageIndex];
        float pdfOffsetY = pdfRect.top - pdfRect.bottom;

        PDF_LAYOUT_MODE layoutMode = [_pdfViewCtrl getPageLayoutMode];
        if (layoutMode == PDF_LAYOUT_MODE_SINGLE ||
            layoutMode == PDF_LAYOUT_MODE_TWO ||
            layoutMode == PDF_LAYOUT_MODE_TWO_LEFT ||
            layoutMode == PDF_LAYOUT_MODE_TWO_RIGHT ||
            layoutMode == PDF_LAYOUT_MODE_TWO_MIDDLE) {
            float tmpPvOffset = pvRect.size.height;
            CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
            CGRect tmpDvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:self.pageIndex];
            [_pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
        } else if (layoutMode == PDF_LAYOUT_MODE_CONTINUOUS) {
            if ([_pdfViewCtrl getCurrentPage] == [_pdfViewCtrl getPageCount] - 1) {
                float tmpPvOffset = pvRect.size.height;
                CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
                CGRect tmpDvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:self.pageIndex];
                [_pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
            } else {
                FSPointF *jumpPdfPoint = [[FSPointF alloc] init];
                [jumpPdfPoint set:oldPdfPoint.x y:oldPdfPoint.y - pdfOffsetY];
                [_pdfViewCtrl gotoPage:self.pageIndex withDocPoint:jumpPdfPoint animated:YES];
            }
        }
    }
}

- (void)keyboardWasHidden:(NSNotification *)aNotification {
    _keyboardShown = NO;

    PDF_LAYOUT_MODE layoutMode = [_pdfViewCtrl getPageLayoutMode];
    if (layoutMode == PDF_LAYOUT_MODE_SINGLE ||
        layoutMode == PDF_LAYOUT_MODE_TWO ||
        layoutMode == PDF_LAYOUT_MODE_TWO_LEFT ||
        layoutMode == PDF_LAYOUT_MODE_TWO_RIGHT ||
        layoutMode == PDF_LAYOUT_MODE_TWO_MIDDLE ||
        self.pageIndex == [_pdfViewCtrl getPageCount] - 1) {
        [_pdfViewCtrl setBottomOffset:0];
    }
}

- (void)onPageChangedFrom:(int)oldIndex to:(int)newIndex {
    [self save];
}

- (void)save {
    if (_textView && !_isSaved) {
        _isSaved = YES;

        if (_textView.text.length > 0) {
            CGRect textFrame = _textView.frame;
            NSString *content = [StringDrawUtil getWrappedStringInTextView:_textView];

            FSRectF *rect = [_pdfViewCtrl convertPageViewRectToPdfRect:textFrame pageIndex:self.pageIndex];
            FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:self.pageIndex];
            if (!page) {
                return;
            }
            FSFreeText *annot = (FSFreeText *) [page addAnnot:e_annotFreeText rect:rect];
            annot.NM = [Utility getUUID];
            annot.author = [SettingPreference getAnnotationAuthor];
            //            [annot setBorderInfo:({
            //                       FSBorderInfo *borderInfo = [[FSBorderInfo alloc] init];
            //                       [borderInfo setWidth:1];
            //                       [borderInfo setStyle:e_borderStyleSolid];
            //                       borderInfo;
            //                   })];

            [annot setDefaultAppearance:({
                       FSDefaultAppearance *appearance = [annot getDefaultAppearance];
                       appearance.flags = e_defaultAPFont | e_defaultAPTextColor | e_defaultAPFontSize;
                       NSString *fontName = [_extensionsManager getAnnotFontName:e_annotFreeText];
                       int fontID = [Utility toStandardFontID:fontName];
                       if (fontID == -1) {
                           appearance.font = [[FSFont alloc] initWithFontName:fontName fontStyles:0 weight:0 charset:e_fontCharsetDefault];
                       } else {
                           appearance.font = [[FSFont alloc] initWithStandardFontID:fontID];
                       }
                       appearance.fontSize = [_extensionsManager getAnnotFontSize:e_annotFreeText];
                       unsigned int color = [_extensionsManager getAnnotColor:e_annotFreeText];
                       appearance.textColor = color;
                       appearance;
                   })];
            int opacity = [_extensionsManager getAnnotOpacity:e_annotFreeText];
            annot.opacity = opacity / 100.0f;
            annot.contents = content;
            annot.createDate = [NSDate date];
            annot.modifiedDate = [NSDate date];
            annot.subject = @"Textbox";
            annot.flags = e_annotFlagPrint;
            [annot resetAppearanceStream];
            // move annot if exceed page edge, as the annot size may be changed after reset ap (especially for Chinese char, the line interspace is changed)
            {
                FSRectF *rect = annot.fsrect;
                if (rect.bottom < 0) {
                    rect.top -= rect.bottom;
                    rect.bottom = 0;
                    annot.fsrect = rect;
                    [annot resetAppearanceStream];
                }
            }
            if (annot) {
                id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
                [annotHandler addAnnot:annot addUndo:YES];
            }
        }

        [_textView resignFirstResponder];
        [_textView removeFromSuperview];
        _textView = nil;
        self.rect = CGRectZero;
        self.isPanCreate = NO;
        self.pageIsAlreadyExist = NO;

        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

// useless ?
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event onView:(UIView *)view {
    if (_textView != nil) {
        CGPoint pt = [_textView convertPoint:point fromView:view];
        if (CGRectContainsPoint(_textView.bounds, pt)) {
            return _textView;
        }
    }
    return nil;
}

- (void)dismissKeyboard {
    [_textView resignFirstResponder];
}

- (void)orientationChanges:(NSNotification *)note {
    UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
    if (DEVICE_iPHONE) {
        if (((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) >= (375 * 667)) && (o == UIDeviceOrientationLandscapeLeft || o == UIDeviceOrientationLandscapeRight)) {
            UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
            doneView.backgroundColor = [UIColor clearColor];
            _textView.inputAccessoryView = doneView;
        }
    } else if (((STYLE_CELLWIDTH_IPHONE * STYLE_CELLHEIHGT_IPHONE) >= (375 * 667)) && (o == UIDeviceOrientationPortrait || o == UIDeviceOrientationPortraitUpsideDown)) {
        UIView *doneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 40)];
        doneView.backgroundColor = [UIColor clearColor];
        // doneView.backgroundColor = [UIColor colorWithRGBHex:0xfffbdb];
        UIButton *doneBT = [UIButton buttonWithType:UIButtonTypeCustom];
        [doneBT setBackgroundImage:[UIImage imageNamed:@"common_keyboard_done"] forState:UIControlStateNormal];
        [doneBT addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
        [doneView addSubview:doneBT];
        [doneBT mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(doneView.mas_right).offset(0);
            make.top.equalTo(doneView.mas_top).offset(0);
            make.size.mas_equalTo(CGSizeMake(40, 40));
        }];
        _textView.inputAccessoryView = doneView;
    }
}

@end
