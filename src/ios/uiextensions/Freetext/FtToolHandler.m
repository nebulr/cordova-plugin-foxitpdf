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

#import "FtToolHandler.h"
#import "ColorUtility.h"
#import "StringDrawUtil.h"
#import "UIExtensionsManager+Private.h"
#import "Utility.h"

@interface FtToolHandler () <UITextViewDelegate>

@property (nonatomic, assign) CGPoint tapPoint;
@property (nonatomic, assign) BOOL pageIsAlreadyExist;
@property (nonatomic, strong) FSPointF *originalDibPoint;

@end

@implementation FtToolHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
    int _currentPageIndex;
    CGRect _keyboardFrame;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        _type = e_annotFreeText;

        _isTypewriterToolbarActive = YES;
        _keyboardFrame = CGRectZero;
    }
    return self;
}

- (NSString *)getName {
    return Tool_Freetext;
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
        _currentPageIndex = pageIndex;
        self.pageIsAlreadyExist = YES;
    }
    BOOL isEditing = (_textView && !_isSaved);
    [self save];
    _isSaved = NO;
    if (_extensionsManager.currentToolHandler == self) {
        CGPoint point = CGPointZero;
        if (recognizer) {
            point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
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

        self.originalDibPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(point.x, point.y, testSize.width, testSize.height)];
        _textView.delegate = self;
        if (OS_ISVERSION7) {
            _textView.textContainerInset = UIEdgeInsetsMake(2, -4, 2, -4);
        } else {
            _textView.contentInset = UIEdgeInsetsMake(-8, -8, -8, -8);
        }
        _textView.backgroundColor = [UIColor clearColor];
        UInt32 color = [_extensionsManager getAnnotColor:e_annotFreeText];
        float opacity = [_extensionsManager getAnnotOpacity:e_annotFreeText];
        BOOL isMappingColorMode = (_pdfViewCtrl.colorMode == e_colorModeMapping);
        if (isMappingColorMode && color == 0) {
            color = 16775930;
        }
        if (!isMappingColorMode && color == 16775930) {
            color = 0;
        }
        _textView.textColor = [UIColor colorWithRGBHex:color alpha:opacity];
        _textView.font = font;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.showsHorizontalScrollIndicator = NO;
        _textView.scrollEnabled = NO;
        _textView.clipsToBounds = NO;
        [[_pdfViewCtrl getPageView:pageIndex] addSubview:_textView];

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
    if (isEditing) {
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer {
    return NO;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (_extensionsManager.currentToolHandler == self) {
        if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            if (_textView) {
                CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
                if (_textView == [[_pdfViewCtrl getPageView:pageIndex] hitTest:point withEvent:nil]) {
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
        CGRect frame = _textView.frame;
        frame.origin = [_pdfViewCtrl convertPdfPtToPageViewPt:self.originalDibPoint pageIndex:pageIndex];
        frame.size = CGSizeMake([_pdfViewCtrl getPageViewWidth:pageIndex] - frame.origin.x, [_pdfViewCtrl getPageViewHeight:pageIndex] - frame.origin.y);
        _textView.frame = frame;

        float fontSize = [_extensionsManager getAnnotFontSize:e_annotFreeText];
        fontSize = [Utility convertWidth:fontSize fromPageViewToPDF:_pdfViewCtrl pageIndex:pageIndex];
        _textView.font = [self getSysFont:_textView.font.fontName size:fontSize];
        [self textViewDidChange:_textView];
    }
}

- (UIFont *)getSysFont:(NSString *)name size:(float)size {
    UIFont *font = [UIFont fontWithName:[Utility convert2SysFontString:name] size:size];
    if (!font) {
        font = [UIFont systemFontOfSize:size];
    }
    return font;
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    CGSize oneSize = [Utility getTestSize:textView.font];
    CGPoint point = textView.frame.origin;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize size = [textView.text boundingRectWithSize:CGSizeMake([_pdfViewCtrl getPageViewWidth:_currentPageIndex] - point.x - oneSize.width, 99999) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : textView.font, NSParagraphStyleAttributeName : paragraphStyle} context:nil].size;

    size.width += oneSize.width;
    size.height += oneSize.height;
    CGRect frame = textView.frame;
    frame.size = size;
    textView.frame = frame;
    float textViewHeight = textView.frame.origin.y + textView.frame.size.height;
    float textViewWidth = textView.frame.origin.x + textView.frame.size.width;

    if (textViewHeight >= ([_pdfViewCtrl getPageViewHeight:_currentPageIndex] - 20)) {
        CGRect textViewFrame = textView.frame;
        textViewFrame.origin.y -= (textViewHeight - [_pdfViewCtrl getPageViewHeight:_currentPageIndex]);
        textView.frame = textViewFrame;
    }
    if (textViewWidth >= ([_pdfViewCtrl getPageViewWidth:_currentPageIndex] - 20)) {
        CGRect textViewFrame = textView.frame;
        textViewFrame.origin.x -= (textViewWidth - [_pdfViewCtrl getPageViewWidth:_currentPageIndex]);
        textView.frame = textViewFrame;
    }

    if (textView.frame.size.height >= ([_pdfViewCtrl getPageViewHeight:_currentPageIndex] - 20)) {
        [textView endEditing:YES];
    }
    if (textView.frame.size.width >= ([_pdfViewCtrl getPageViewWidth:_currentPageIndex] - 20)) {
        [textView endEditing:YES];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self save];
}

#pragma mark - keyboard
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)keyboardWasShown:(NSNotification *)aNotification {
    if (_keyboardShown)
        return;
    _keyboardShown = YES;
    NSDictionary *info = [aNotification userInfo];
    NSValue *frame = nil;
    frame = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    CGRect keyboardFrame = [frame CGRectValue];
    _keyboardFrame = keyboardFrame;
    CGRect textFrame = _textView.frame;

    CGPoint oldPvPoint = [_pdfViewCtrl convertDisplayViewPtToPageViewPt:CGPointMake(0, 0) pageIndex:_currentPageIndex];
    FSPointF *oldPdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:oldPvPoint pageIndex:_currentPageIndex];

    CGRect dvAnnotRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:textFrame pageIndex:_currentPageIndex];
    float positionY;
    if (DEVICE_iPHONE && !OS_ISVERSION8 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        positionY = CGRectGetWidth(_pdfViewCtrl.bounds) - dvAnnotRect.origin.y - dvAnnotRect.size.height;
    } else {
        positionY = CGRectGetHeight(_pdfViewCtrl.bounds) - dvAnnotRect.origin.y - dvAnnotRect.size.height;
    }

    if (positionY < keyboardFrame.size.height) {
        float dvOffsetY = keyboardFrame.size.height - positionY + 60;
        CGRect offsetRect = CGRectMake(0, 0, 100, dvOffsetY);

        CGRect pvRect = [_pdfViewCtrl convertDisplayViewRectToPageViewRect:offsetRect pageIndex:_currentPageIndex];
        FSRectF *pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:_currentPageIndex];
        float pdfOffsetY = pdfRect.top - pdfRect.bottom;

        if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_SINGLE || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_RIGHT || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_MIDDLE) {
            float tmpPvOffset = pvRect.size.height;
            CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
            CGRect tmpDvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:_currentPageIndex];
            [_pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
        } else if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_CONTINUOUS) {
            if ([_pdfViewCtrl getCurrentPage] == [_pdfViewCtrl getPageCount] - 1) {
                float tmpPvOffset = pvRect.size.height;
                CGRect tmpPvRect = CGRectMake(0, 0, 10, tmpPvOffset);
                CGRect tmpDvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:tmpPvRect pageIndex:_currentPageIndex];
                [_pdfViewCtrl setBottomOffset:tmpDvRect.size.height];
            } else {
                FSPointF *jumpPdfPoint = [[FSPointF alloc] init];
                [jumpPdfPoint set:oldPdfPoint.x y:oldPdfPoint.y - pdfOffsetY];
                [_pdfViewCtrl gotoPage:_currentPageIndex withDocPoint:jumpPdfPoint animated:YES];
            }
        }
    }
}

- (void)keyboardWasHidden:(NSNotification *)aNotification {
    [_pdfViewCtrl refresh:_currentPageIndex];
    _keyboardShown = NO;

    PDF_LAYOUT_MODE layoutMode = [_pdfViewCtrl getPageLayoutMode];
    if (layoutMode == PDF_LAYOUT_MODE_SINGLE || layoutMode == PDF_LAYOUT_MODE_TWO || _currentPageIndex == [_pdfViewCtrl getPageCount] - 1 || layoutMode == PDF_LAYOUT_MODE_TWO_LEFT || layoutMode == PDF_LAYOUT_MODE_TWO_RIGHT || layoutMode == PDF_LAYOUT_MODE_TWO_MIDDLE) {
        [_pdfViewCtrl setBottomOffset:0];
    }
}

- (void)save {
    if (_textView && !_isSaved) {
        _isSaved = YES;

        if (_textView.text.length > 0) {
            CGRect textFrame = _textView.frame;
            NSString *content = [StringDrawUtil getWrappedStringInTextView:_textView];
            //            StringDrawUtil *strDrawUtil = [[StringDrawUtil alloc] initWithFont:_textView.font];
            //            NSString *content = [strDrawUtil getReturnRefinedString:_textView.text forUITextViewWidth:_textView.bounds.size.width];

            CGRect annotRectPV = CGRectMake(textFrame.origin.x, textFrame.origin.y, textFrame.size.width, textFrame.size.height);
            FSRectF *rect = [_pdfViewCtrl convertPageViewRectToPdfRect:annotRectPV pageIndex:_currentPageIndex];

            FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:_currentPageIndex];
            if (!page)
                return;
            FSFreeText *annot = (FSFreeText *) [page addAnnot:e_annotFreeText rect:rect];
            annot.NM = [Utility getUUID];
            annot.author = [SettingPreference getAnnotationAuthor];
            [annot setIntent:@"FreeTextTypewriter"];

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

            [annot setDefaultAppearance:appearance];
            int opacity = [_extensionsManager getAnnotOpacity:e_annotFreeText];
            annot.opacity = opacity / 100.0f;
            [annot setContent:content];
            annot.createDate = [NSDate date];
            annot.modifiedDate = [NSDate date];
            annot.subject = @"Typewriter";
            annot.flags = e_annotFlagPrint;

            [annot resetAppearanceStream];

            if (annot) {
                id<IAnnotHandler> annotHandler = [_extensionsManager getAnnotHandlerByAnnot:annot];
                [annotHandler addAnnot:annot addUndo:YES];
            }
        }
        [_textView resignFirstResponder];
        [_textView removeFromSuperview];

        // Tricky fix ios7 crash

        double delayInSeconds = .1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                });
        _textView = nil;
        self.pageIsAlreadyExist = NO;

        [[NSNotificationCenter defaultCenter] removeObserver:self];
        if (!_isTypewriterToolbarActive) {
            _isTypewriterToolbarActive = YES;
            [_extensionsManager setCurrentToolHandler:nil];
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (!_keyboardShown || CGRectIsEmpty(_keyboardFrame))
        return;

    int pageIndex = _currentPageIndex;
    CGPoint oldPvPoint = [_pdfViewCtrl convertDisplayViewPtToPageViewPt:CGPointMake(0, 0) pageIndex:pageIndex];
    FSPointF *oldPdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:oldPvPoint pageIndex:pageIndex];

    CGRect dvAnnotRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:_textView.frame pageIndex:pageIndex];
    if ((CGRectGetHeight(_pdfViewCtrl.bounds) - dvAnnotRect.origin.y - dvAnnotRect.size.height) < _keyboardFrame.size.height) {
        float dvOffsetY = _keyboardFrame.size.height - (CGRectGetHeight(_pdfViewCtrl.bounds) - dvAnnotRect.origin.y - dvAnnotRect.size.height) + 60;
        CGRect offsetRect = CGRectMake(0, 0, 100, dvOffsetY);

        CGRect pvRect = [_pdfViewCtrl convertDisplayViewRectToPageViewRect:offsetRect pageIndex:pageIndex];
        FSRectF *pdfRect = [_pdfViewCtrl convertPageViewRectToPdfRect:pvRect pageIndex:pageIndex];
        float pdfOffsetY = pdfRect.top - pdfRect.bottom;

        if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_SINGLE || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_LEFT || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_RIGHT || [_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_TWO_MIDDLE) {
            [_extensionsManager.pdfViewCtrl setBottomOffset:0];
        } else if ([_pdfViewCtrl getPageLayoutMode] == PDF_LAYOUT_MODE_CONTINUOUS) {
            if ([_pdfViewCtrl getCurrentPage] == [_pdfViewCtrl getPageCount] - 1) {
                [_extensionsManager.pdfViewCtrl setBottomOffset:0];
            } else {
                FSPointF *jumpPdfPoint = [[FSPointF alloc] init];
                [jumpPdfPoint setX:oldPdfPoint.x];
                [jumpPdfPoint setY:oldPdfPoint.y - pdfOffsetY];
                [_pdfViewCtrl gotoPage:pageIndex withDocPoint:jumpPdfPoint animated:YES];
            }
        }
    } else
        [_extensionsManager.pdfViewCtrl setBottomOffset:0];

    _keyboardFrame = CGRectZero;
    _keyboardShown = NO;
    [_textView resignFirstResponder];
    [_textView removeFromSuperview];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)scrollView {
    [self save];
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)scrollView {
}


- (void)exitWithoutSave {
    [_textView resignFirstResponder];
    [_textView removeFromSuperview];
    _textView = nil;
}

@end
