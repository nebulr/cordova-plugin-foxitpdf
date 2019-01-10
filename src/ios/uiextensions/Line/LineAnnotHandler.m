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

#import "LineAnnotHandler.h"
#import "ColorUtility.h"
#import "FSAnnotAttributes.h"
#import "FSAnnotExtent.h"
#import "FSUndo.h"
#import "LineToolHandler.h"
#import "MenuControl.h"
#import "MenuItem.h"
#import "ReplyTableViewController.h"
#import "ReplyUtil.h"
#import "UIExtensionsManager+Private.h"
#import "Utility.h"
#import <FoxitRDK/FSPDFViewControl.h>

@interface LineAnnotHandler () <IDocEventListener>

@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, assign) CGRect oldRect;
@property (nonatomic, strong) MenuControl *menuControl;
@property (nonatomic, assign) BOOL isShowStyle;
@property (nonatomic, assign) BOOL shouldShowMenu;
@property (nonatomic, assign) BOOL shouldShowPropety;
@property (nonatomic, strong) UIImage *annotImage;
@property (nonatomic, strong) NSArray *measureRatioInfo;

// for undo/redo in pan
@property (nonatomic, strong) FSAnnotAttributes *attributesBeforeModify; // for undo

@end

@implementation LineAnnotHandler {
    UIExtensionsManager *_extensionsManager;
    FSPDFViewCtrl *_pdfViewCtrl;
}

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager {
    self = [super init];
    if (self) {
        _extensionsManager = extensionsManager;
        _pdfViewCtrl = extensionsManager.pdfViewCtrl;
        self.colors = @[ @0xFF9F40, @0x8080FF, @0xBAE94C, @0xFFF160, @0xC3C3C3, @0xFF4C4C, @0x669999, @0xC72DA1, @0x996666, @0x000000 ];
        self.isShowStyle = NO;
        self.editAnnot = nil;
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
    }
    return self;
}

- (FSAnnotType)getType {
    return e_annotLine;
}

- (BOOL)annotCanAnswer:(FSAnnot *)annot {
    return YES;
}

- (FSRectF *)getAnnotBBox:(FSAnnot *)annot {
    return annot.fsrect;
}

- (BOOL)isHitAnnot:(FSAnnot *)annot point:(FSPointF *)point {
    int pageIndex = annot.pageIndex;
    CGPoint startPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:[(FSLine *) annot getStartPoint] pageIndex:pageIndex];
    CGPoint endPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:[(FSLine *) annot getEndPoint] pageIndex:pageIndex];
    CGPoint pvPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:point pageIndex:pageIndex];
    return [self isPoint:pvPoint
        inLineWithLineWidth:annot.lineWidth
                 startPoint:startPoint
                   endPoint:endPoint];
}

- (BOOL)isPoint:(CGPoint)point inLineWithLineWidth:(float)lineWidth startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    CGPoint thePoint = point;
    // ax + by + c = 0
    float a = startPoint.y - endPoint.y;
    float b = endPoint.x - startPoint.x;
    float c = startPoint.x * endPoint.y - startPoint.y * endPoint.x;
    float distanceSquare = powf((a * thePoint.x + b * thePoint.y + c), 2) / (a * a + b * b);
    const float tolerance = 20.0f + lineWidth / 2;
    if (distanceSquare < powf(tolerance, 2)) {
        if (((startPoint.x - tolerance < thePoint.x && thePoint.x < endPoint.x + tolerance) ||
             (endPoint.x - tolerance < thePoint.x && thePoint.x < startPoint.x + tolerance)) &&
            ((startPoint.y - tolerance < thePoint.y && thePoint.y < endPoint.y + tolerance) ||
             (endPoint.y - tolerance < thePoint.y && thePoint.y < startPoint.y + tolerance))) {
            return YES;
        }
    }
    return NO;
}

// get line annot's pageview rectangle (including drag dot)
- (CGRect)getRectForSelectedLine:(FSLine *)line {
    int pageIndex = line.pageIndex;
    CGPoint startPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:[line getStartPoint] pageIndex:pageIndex];
    CGPoint endPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:[line getEndPoint] pageIndex:pageIndex];
    CGFloat lineWidth = [Utility convertWidth:line.lineWidth fromPageViewToPDF:_pdfViewCtrl pageIndex:pageIndex];
    CGPoint dotStartPoint, dotEndPoint;
    [self getDotStartPoint:&dotStartPoint dotEndPoint:&dotEndPoint withStartPoint:startPoint endPoint:endPoint lineWidth:lineWidth];
    UIImage *dragDot = [UIImage imageNamed:@"annotation_drag.png"];
    return CGRectInset([Utility convertToCGRect:dotStartPoint p2:dotEndPoint], -dragDot.size.width / 2, -dragDot.size.height / 2);
}

- (void)onAnnotSelected:(FSAnnot *)annot {
    self.editAnnot = annot;
    self.attributesBeforeModify = [FSAnnotAttributes attributesWithAnnot:annot];

    CGRect rect = [self getRectForSelectedLine:(FSLine *) annot];
    NSMutableArray *array = [NSMutableArray array];

    //isArrowLine
    LineToolHandler *toolHandler = [_extensionsManager getToolHandlerByName:Tool_Line];
    FSLine *annot1 = (FSLine *) annot;
    toolHandler.isArrowLine = [[annot1 getIntent] isEqualToString:@"LineArrow"];
    toolHandler.isDistanceTool = NO;

    MenuItem *commentItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kOpen") object:self action:@selector(comment)];
    MenuItem *openItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kOpen") object:self action:@selector(comment)];
    MenuItem *replyItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kReply") object:self action:@selector(reply)];
    MenuItem *styleItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kStyle") object:self action:@selector(showStyle)];
    MenuItem *deleteItem = [[MenuItem alloc] initWithTitle:FSLocalizedString(@"kDelete") object:self action:@selector(delete)];
    if (annot.canModify) {
        if (annot.contents == nil || [annot.contents isEqualToString:@""]) {
            [array addObject:commentItem];
        } else {
            [array addObject:openItem];
        }

        [array addObject:replyItem];
        [array addObject:styleItem];
        [array addObject:deleteItem];
    } else {
        [array addObject:commentItem];
        if (annot.canReply) {
            [array addObject:replyItem];
        }
    }

    CGRect dvRect = rect;
    dvRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:dvRect pageIndex:annot.pageIndex];
    _extensionsManager.menuControl.menuItems = array;
    [_extensionsManager.menuControl setRect:dvRect margin:0];
    [_extensionsManager.menuControl showMenu];

    self.shouldShowMenu = YES;
    self.shouldShowPropety = NO;

    self.startPoint = [annot1 getStartPoint];
    self.endPoint = [annot1 getEndPoint];
    self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
    
    rect = CGRectInset(rect, -20, -20);
    [_pdfViewCtrl refresh:rect pageIndex:annot.pageIndex needRender:YES];
    
    if ([[annot1 getIntent] isEqualToString:@"LineDimension"]){
        [_pdfViewCtrl refresh:annot.pageIndex];
        _measureRatioInfo = [Utility getDistanceUnitInfo:[annot1 getMeasureRatio]];
        
        toolHandler.isDistanceTool = YES;
        toolHandler.isArrowLine = NO;
    }
}

-(void)updateDistanceDataFromStartPoint:(FSPointF *)start toEndPoint:(FSPointF *)end {
    FSLine *lineAnnot = (FSLine *)self.editAnnot;
    
    NSString *measureRatio = lineAnnot ? [lineAnnot getMeasureRatio]:_extensionsManager.distanceUnit;
    float distance = [Utility getDistanceFromX:start toY:end withUnit:measureRatio];
    
    NSString *unitStr = lineAnnot ? [lineAnnot getMeasureUnit:0] : [_measureRatioInfo objectAtIndex:3];
    
    NSString *distanceContent = [NSString stringWithFormat:@"%.2f%@",distance,unitStr];
    [self.editAnnot setContent:distanceContent];
}

- (void)comment {
    NSMutableArray *replyAnnots = [[NSMutableArray alloc] init];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
    self.replyVC = replyCtr;
    replyCtr.isNeedReply = NO;
    NSMutableArray *array = [NSMutableArray arrayWithArray:replyAnnots];
    [array addObject:_extensionsManager.currentAnnot];
    [replyCtr setTableViewAnnotations:array];

    UINavigationController *navCtr = [[UINavigationController alloc] initWithRootViewController:replyCtr];

    navCtr.delegate = replyCtr;
    navCtr.modalPresentationStyle = UIModalPresentationFormSheet;
    navCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:navCtr animated:YES completion:nil];

    replyCtr.editingDoneHandler = ^() {

        [_extensionsManager setCurrentAnnot:nil];
    };
    replyCtr.editingCancelHandler = ^() {

        [_extensionsManager setCurrentAnnot:nil];
    };
}

- (void)reply {
    NSMutableArray *replyAnnots = [[NSMutableArray alloc] init];
    [ReplyUtil getReplysInDocument:_pdfViewCtrl.currentDoc annot:_extensionsManager.currentAnnot replys:replyAnnots];
    ReplyTableViewController *replyCtr = [[ReplyTableViewController alloc] initWithStyle:UITableViewStylePlain extensionsManager:_extensionsManager];
    self.replyVC = replyCtr;
    replyCtr.isNeedReply = YES;
    NSMutableArray *array = [NSMutableArray arrayWithArray:replyAnnots];
    [array addObject:_extensionsManager.currentAnnot];
    [replyCtr setTableViewAnnotations:array];
    UINavigationController *navCtr = [[UINavigationController alloc] initWithRootViewController:replyCtr];

    navCtr.delegate = replyCtr;
    navCtr.modalPresentationStyle = UIModalPresentationFormSheet;
    navCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:navCtr animated:YES completion:nil];
    replyCtr.editingDoneHandler = ^() {
        [_extensionsManager setCurrentAnnot:nil];
    };
    replyCtr.editingCancelHandler = ^() {

        [_extensionsManager setCurrentAnnot:nil];
    };
}

- (void) delete {
    FSAnnot *annot = _extensionsManager.currentAnnot;
    Task *task = [[Task alloc] init];
    task.run = ^() {
        [self deleteAnnot:annot];
    };
    [_extensionsManager.taskServer executeSync:task];
    [_extensionsManager setCurrentAnnot:nil];
}

- (void)showStyle {
    [_extensionsManager.propertyBar setColors:self.colors];
    
    FSAnnot *annot = _extensionsManager.currentAnnot;
    FSLine *annot1 = (FSLine *) annot;
    
    if ([[annot1 getIntent] isEqualToString:@"LineDimension"]) {
        
        [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_DISTANCE_UNIT frame:CGRectZero];
        [_extensionsManager.propertyBar setProperty:PROPERTY_DISTANCE_UNIT stringValue:annot1 ? [annot1 getMeasureRatio] : _extensionsManager.distanceUnit];
        [_extensionsManager.propertyBar setDistanceLayoutsForbidEdit];
    }else{
        [_extensionsManager.propertyBar resetBySupportedItems:PROPERTY_COLOR | PROPERTY_OPACITY | PROPERTY_LINEWIDTH frame:CGRectZero];
        [_extensionsManager.propertyBar setProperty:PROPERTY_LINEWIDTH intValue:annot.lineWidth];
        
    }
    [_extensionsManager.propertyBar setProperty:PROPERTY_COLOR intValue:annot.color];
    [_extensionsManager.propertyBar setProperty:PROPERTY_OPACITY intValue:annot.opacity * 100.0];
    
    [_extensionsManager.propertyBar addListener:_extensionsManager];

    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:annot.pageIndex];
    NSArray *array = [NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]];
    [_extensionsManager.propertyBar showPropertyBar:showRect inView:_pdfViewCtrl viewsCanMove:array];
    
    self.isShowStyle = YES;
    self.shouldShowMenu = NO;
    self.shouldShowPropety = YES;
}

- (void)onAnnotDeselected:(FSAnnot *)annot {
    if (_extensionsManager.menuControl.isMenuVisible) {
        [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
    }
    if (_extensionsManager.propertyBar.isShowing) {
        [_extensionsManager.propertyBar dismissPropertyBar];
        self.isShowStyle = NO;
    }
    self.shouldShowMenu = NO;
    self.shouldShowPropety = NO;
    self.annotImage = nil;
    self.editAnnot = nil;

    if (![self.attributesBeforeModify isEqualToAttributes:[FSAnnotAttributes attributesWithAnnot:annot]]) {
        [self modifyAnnot:annot addUndo:YES];
    }
    self.attributesBeforeModify = nil;
    
    int pageIndex = annot.pageIndex;
    CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
    newRect = CGRectInset(newRect, -20, -20);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:newRect pageIndex:pageIndex needRender:YES];
    });
    
    FSLine *lineAnnot = (FSLine *)annot;
    if ([[lineAnnot getIntent] isEqualToString:@"LineDimension"]){
        [_pdfViewCtrl refresh:annot.pageIndex];
    }
}

- (void)addAnnot:(FSAnnot *)annot {
    [self addAnnot:annot addUndo:YES];
}

- (void)addAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    int pageIndex = annot.pageIndex;
    FSPDFPage *page = [annot getPage];

    if (addUndo) {
        FSAnnotAttributes *attributes = [FSAnnotAttributes attributesWithAnnot:annot];
        [_extensionsManager addUndoItem:[UndoItem itemForUndoAddAnnotWithAttributes:attributes page:page annotHandler:self]];
    }

    [_extensionsManager onAnnotAdded:page annot:annot];
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect = CGRectInset(rect, -20, -20);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
}

- (void)modifyAnnot:(FSAnnot *)annot {
    [self modifyAnnot:annot addUndo:YES];
}

- (void)modifyAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    FSPDFPage *page = [annot getPage];
    if (!page) {
        return;
    }

    if ([annot canModify] && addUndo) {
        annot.modifiedDate = [NSDate date];
        [_extensionsManager addUndoItem:[UndoItem itemForUndoModifyAnnotWithOldAttributes:self.attributesBeforeModify newAttributes:[FSAnnotAttributes attributesWithAnnot:annot] pdfViewCtrl:_pdfViewCtrl page:page annotHandler:self]];
    }

    [_extensionsManager onAnnotModified:page annot:annot];
    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect = CGRectInset(rect, -20, -20);
    int pageIndex = annot.pageIndex;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
}

- (void)removeAnnot:(FSAnnot *)annot {
    [self removeAnnot:annot addUndo:YES];
}

- (void)removeAnnot:(FSAnnot *)annot addUndo:(BOOL)addUndo {
    FSLine *lineAnnot = (FSLine *)annot;
    if ([[lineAnnot getIntent] isEqualToString:@"LineDimension"]){
       [_pdfViewCtrl refresh:annot.pageIndex];
    }
    
    int pageIndex = annot.pageIndex;
    FSPDFPage *page = [annot getPage];

    if (addUndo) {
        FSAnnotAttributes *attributes = self.attributesBeforeModify ?: [FSAnnotAttributes attributesWithAnnot:annot];
        [_extensionsManager addUndoItem:[UndoItem itemForUndoDeleteAnnotWithAttributes:attributes page:page annotHandler:self]];
    }
    self.attributesBeforeModify = nil;

    CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:annot.pageIndex];
    rect = CGRectInset(rect, -20, -20);

    [_extensionsManager onAnnotWillDelete:page annot:annot];
    [page removeAnnot:annot];
    [_extensionsManager onAnnotDeleted:page annot:annot];

    dispatch_async(dispatch_get_main_queue(), ^{
        [_pdfViewCtrl refresh:rect pageIndex:pageIndex];
    });
}

- (void)deleteAnnot:(FSAnnot *)annot {
    [self removeAnnot:annot];
}

- (BOOL)onPageViewLongPress:(int)pageIndex recognizer:(UILongPressGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTap:(int)pageIndex recognizer:(UITapGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:annot.pageIndex]];
    FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:annot.pageIndex];
    if (_extensionsManager.currentAnnot == annot) {
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
            return YES;
        } else {
            [_extensionsManager setCurrentAnnot:nil];
            return YES;
        }
    } else {
        [_extensionsManager setCurrentAnnot:annot];
        return YES;
    }
    return NO;
}

- (BOOL)onPageViewPan:(int)pageIndex recognizer:(UIPanGestureRecognizer *)recognizer annot:(FSAnnot *)annot {
    //move annotation or resize it

    if (_extensionsManager.currentAnnot != annot) {
        return NO;
    }

    FSLine *annot1 = (FSLine *) annot;
    CGPoint point = [recognizer locationInView:[_pdfViewCtrl getPageView:pageIndex]];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.shouldShowMenu = NO;
        self.shouldShowPropety = NO;
        if ([_extensionsManager.menuControl isMenuVisible]) {
            [_extensionsManager.menuControl hideMenu];
        }
        if (_extensionsManager.propertyBar.isShowing && self.isShowStyle) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
        _editType = EDITANNOT_LINE_TYPE_UNKNOWN;
        self.startPoint = [annot1 getStartPoint];
        self.endPoint = [annot1 getEndPoint];
        self.oldRect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot1.fsrect pageIndex:pageIndex];

        CGPoint pvStartPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:[annot1 getStartPoint] pageIndex:pageIndex];
        CGPoint pvEndPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:[annot1 getEndPoint] pageIndex:pageIndex];
        UIImage *dragDot = [UIImage imageNamed:@"annotation_drag.png"];
        double newStartX = pvStartPoint.x;
        double newStartY = pvStartPoint.y;
        double newEndX = pvEndPoint.x;
        double newEndY = pvEndPoint.y;
        double LINE_DOT_MARGIN = [UIImage imageNamed:@"annotation_drag.png"].size.width / 2;
        if (pvStartPoint.x == pvEndPoint.x) {
            if (pvStartPoint.y < pvEndPoint.y) {
                newStartY -= LINE_DOT_MARGIN;
                newEndY += LINE_DOT_MARGIN;
            } else if (pvStartPoint.y > pvEndPoint.y) {
                newStartY += LINE_DOT_MARGIN;
                newEndY -= LINE_DOT_MARGIN;
            }
        } else if (pvStartPoint.x < pvEndPoint.x) {
            double angle = atan((pvEndPoint.y - pvStartPoint.y) / (pvEndPoint.x - pvStartPoint.x));
            newStartX = pvStartPoint.x - LINE_DOT_MARGIN * cos(angle);
            newStartY = pvStartPoint.y - LINE_DOT_MARGIN * sin(angle);
            newEndX = pvEndPoint.x + LINE_DOT_MARGIN * cos(angle);
            newEndY = pvEndPoint.y + LINE_DOT_MARGIN * sin(angle);
        } else if (pvStartPoint.x > pvEndPoint.x) {
            double angle = atan((pvEndPoint.y - pvStartPoint.y) / (pvStartPoint.x - pvEndPoint.x));
            newStartX = pvStartPoint.x + LINE_DOT_MARGIN * cos(angle);
            newStartY = pvStartPoint.y - LINE_DOT_MARGIN * sin(angle);
            newEndX = pvEndPoint.x - LINE_DOT_MARGIN * cos(angle);
            newEndY = pvEndPoint.y + LINE_DOT_MARGIN * sin(angle);
        }

        CGRect startPointRect = CGRectMake(newStartX - dragDot.size.width / 2, newStartY - dragDot.size.width / 2, dragDot.size.width * 2, dragDot.size.width);
        startPointRect = CGRectInset(startPointRect, -10, -10);
        CGRect endPointRect = CGRectMake(newEndX - dragDot.size.width / 2, newEndY - dragDot.size.width / 2, dragDot.size.width * 2, dragDot.size.width);
        endPointRect = CGRectInset(endPointRect, -10, -10);
        if (CGRectContainsPoint(startPointRect, point)) {
            _editType = EDITANNOT_LINE_TYPE_START_POINT;
        } else if (CGRectContainsPoint(endPointRect, point)) {
            _editType = EDITANNOT_LINE_TYPE_END_POINT;
        } else //if ([self isPoint:point inLineWithLineWidth:annot.lineWidth startPoint:pvStartPoint endPoint:pvEndPoint])
        {
            _editType = EDITANNOT_LINE_TYPE_FULL;
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (_editType == EDITANNOT_LINE_TYPE_UNKNOWN) {
            return NO;
        }
        CGPoint translationPoint = [recognizer translationInView:[_pdfViewCtrl getPageView:pageIndex]];
        CGPoint lastPoint = CGPointMake(point.x - translationPoint.x, point.y - translationPoint.y);
        FSPointF *cp = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:pageIndex];
        FSPointF *lp = [_pdfViewCtrl convertPageViewPtToPdfPt:lastPoint pageIndex:pageIndex];
        float tw = cp.x - lp.x;
        float th = cp.y - lp.y;

        FSPDFPage *page = [_pdfViewCtrl.currentDoc getPage:pageIndex];
        FSRotation rotation = [page getRotation];
        CGSize pageSize = CGSizeMake([page getWidth], [page getHeight]);
        if (_editType == EDITANNOT_LINE_TYPE_START_POINT || _editType == EDITANNOT_LINE_TYPE_FULL) {
            if (!annot.canModify) {
                return YES;
            }
            _startPoint.x += tw;
            _startPoint.y += th;
            // Not over page limit
            if (rotation != 1 && rotation != 3) {
                if (_startPoint.x < 0) {
                    _startPoint.x = 0;
                } else if (_startPoint.x > pageSize.width) {
                    _startPoint.x = pageSize.width;
                }
                if (_startPoint.y < 0) {
                    _startPoint.y = 0;
                } else if (_startPoint.y > pageSize.height) {
                    _startPoint.y = pageSize.height;
                }
            } else if (rotation == 1 || rotation == 3) {
                if (_startPoint.x < 0) {
                    _startPoint.x = 0;
                } else if (_startPoint.x > pageSize.height) {
                    _startPoint.x = pageSize.height;
                }
                if (_startPoint.y < 0) {
                    _startPoint.y = 0;
                } else if (_startPoint.y > pageSize.width) {
                    _startPoint.y = pageSize.width;
                }
            }
            annot1.startPoint = _startPoint;
        }
        if (_editType == EDITANNOT_LINE_TYPE_END_POINT || _editType == EDITANNOT_LINE_TYPE_FULL) {
            if (!annot.canModify) {
                return YES;
            }
            _endPoint.x += tw;
            _endPoint.y += th;
            if (rotation != 1 && rotation != 3) {
                if (_endPoint.x < 0) {
                    _endPoint.x = 0;
                } else if (_endPoint.x > pageSize.width) {
                    _endPoint.x = pageSize.width;
                }
                if (_endPoint.y < 0) {
                    _endPoint.y = 0;
                } else if (_endPoint.y > pageSize.height) {
                    _endPoint.y = pageSize.height;
                }
            } else if (rotation == 1 || rotation == 3) {
                if (_endPoint.x < 0) {
                    _endPoint.x = 0;
                } else if (_endPoint.x > pageSize.height) {
                    _endPoint.x = pageSize.height;
                }
                if (_endPoint.y < 0) {
                    _endPoint.y = 0;
                } else if (_endPoint.y > pageSize.width) {
                    _endPoint.y = pageSize.width;
                }
            }
            annot1.endPoint = _endPoint;
        }
        [annot1 resetAppearanceStream];

        [recognizer setTranslation:CGPointZero inView:[_pdfViewCtrl getPageView:pageIndex]];

        FSRectF *dibRect = [Utility convertToFSRect:_startPoint p2:_endPoint];
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:dibRect pageIndex:pageIndex];
        CGRect unionRect = CGRectUnion(self.oldRect, newRect);
        unionRect = CGRectInset(unionRect, -110, -100);
        self.annotImage = [Utility getAnnotImage:annot pdfViewCtrl:_pdfViewCtrl];
        [_pdfViewCtrl refresh:pageIndex needRender:NO];
        self.oldRect = newRect;
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (_editType != EDITANNOT_LINE_TYPE_UNKNOWN) {
            if (annot.canModify) {
                [self modifyAnnot:annot1 addUndo:NO];
            }
        }
        CGRect newRect = [self getRectForSelectedLine:annot1];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:newRect pageIndex:annot.pageIndex];
        if (self.isShowStyle && !DEVICE_iPHONE) {
            self.shouldShowMenu = NO;
            self.shouldShowPropety = YES;
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:[_pdfViewCtrl getDisplayView] viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        } else {
            self.shouldShowMenu = YES;
            self.shouldShowPropety = NO;
            [_extensionsManager.menuControl setRect:showRect margin:0];
            [_extensionsManager.menuControl showMenu];
        }
        self.oldRect = CGRectZero;
        self.startPoint = nil;
        self.endPoint = nil;
        _editType = EDITANNOT_LINE_TYPE_UNKNOWN;
    }
    
    if ([[annot1 getIntent] isEqualToString:@"LineDimension"]){
        [self updateDistanceDataFromStartPoint:[annot1 getStartPoint] toEndPoint:[annot1 getEndPoint]];
    }
    return YES;
}

- (BOOL)onPageViewShouldBegin:(int)pageIndex recognizer:(UIGestureRecognizer *)gestureRecognizer annot:(FSAnnot *)annot {
    if ([_extensionsManager getAnnotHandlerByAnnot:annot] == self) {
        BOOL canAddAnnot = [Utility canAddAnnotToDocument:_pdfViewCtrl.currentDoc];
        if (!canAddAnnot) {
            return NO;
        }
        CGPoint point = [gestureRecognizer locationInView:[_pdfViewCtrl getPageView:annot.pageIndex]];
        FSPointF *pdfPoint = [_pdfViewCtrl convertPageViewPtToPdfPt:point pageIndex:annot.pageIndex];
        if (pageIndex == annot.pageIndex && [self isHitAnnot:annot point:pdfPoint]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)onPageViewTouchesBegan:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTouchesMoved:(int)pageIndex touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTouchesEnded:(int)pageView touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

- (BOOL)onPageViewTouchesCancelled:(int)pageView touches:(NSSet *)touches withEvent:(UIEvent *)event annot:(FSAnnot *)annot {
    return NO;
}

// get positions of starting and ending dot images
- (void)getDotStartPoint:(CGPoint *)dotStartPoint dotEndPoint:(CGPoint *)dotEndPoint withStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint lineWidth:(CGFloat)lineWidth {
    assert(dotStartPoint != nil);
    assert(dotEndPoint != nil);

    double angle = atan((endPoint.y - startPoint.y) / (endPoint.x - startPoint.x));
    if (angle < 0) {
        angle = -angle;
    }
    if (startPoint.x > endPoint.x && startPoint.y > endPoint.y) {
        startPoint = CGPointMake(startPoint.x - lineWidth * 0.5 * cos(angle), startPoint.y - lineWidth * 0.5 * sin(angle));
        endPoint = CGPointMake(endPoint.x + lineWidth * 0.5 * cos(angle), endPoint.y + lineWidth * 0.5 * sin(angle));
    } else if (startPoint.x > endPoint.x && startPoint.y < endPoint.y) {
        startPoint = CGPointMake(startPoint.x - lineWidth * 0.5 * cos(angle), startPoint.y + lineWidth * 0.5 * sin(angle));
        endPoint = CGPointMake(endPoint.x + lineWidth * 0.5 * cos(angle), endPoint.y - lineWidth * 0.5 * sin(angle));
    } else if (startPoint.x < endPoint.x && startPoint.y < endPoint.y) {
        startPoint = CGPointMake(startPoint.x + lineWidth * 0.5 * cos(angle), startPoint.y + lineWidth * 0.5 * sin(angle));
        endPoint = CGPointMake(endPoint.x - lineWidth * 0.5 * cos(angle), endPoint.y - lineWidth * 0.5 * sin(angle));
    } else if (startPoint.x < endPoint.x && startPoint.y > endPoint.y) {
        startPoint = CGPointMake(startPoint.x + lineWidth * 0.5 * cos(angle), startPoint.y - lineWidth * 0.5 * sin(angle));
        endPoint = CGPointMake(endPoint.x - lineWidth * 0.5 * cos(angle), endPoint.y + lineWidth * 0.5 * sin(angle));
    }

    double newStartX = startPoint.x;
    double newStartY = startPoint.y;
    double newEndX = endPoint.x;
    double newEndY = endPoint.y;
    double LINE_DOT_MARGIN = [UIImage imageNamed:@"annotation_drag.png"].size.width / 2;
    if (startPoint.x == endPoint.x) {
        if (startPoint.y < endPoint.y) {
            newStartY -= LINE_DOT_MARGIN;
            newEndY += LINE_DOT_MARGIN;
        } else if (startPoint.y > endPoint.y) {
            newStartY += LINE_DOT_MARGIN;
            newEndY -= LINE_DOT_MARGIN;
        }
    } else if (startPoint.x < endPoint.x) {
        double angle = atan((endPoint.y - startPoint.y) / (endPoint.x - startPoint.x));
        newStartX = startPoint.x - LINE_DOT_MARGIN * cos(angle);
        newStartY = startPoint.y - LINE_DOT_MARGIN * sin(angle);
        newEndX = endPoint.x + LINE_DOT_MARGIN * cos(angle);
        newEndY = endPoint.y + LINE_DOT_MARGIN * sin(angle);
    } else if (startPoint.x > endPoint.x) {
        double angle = atan((endPoint.y - startPoint.y) / (startPoint.x - endPoint.x));
        newStartX = startPoint.x + LINE_DOT_MARGIN * cos(angle);
        newStartY = startPoint.y - LINE_DOT_MARGIN * sin(angle);
        newEndX = endPoint.x - LINE_DOT_MARGIN * cos(angle);
        newEndY = endPoint.y + LINE_DOT_MARGIN * sin(angle);
    }
    dotStartPoint->x = newStartX;
    dotStartPoint->y = newStartY;
    dotEndPoint->x = newEndX;
    dotEndPoint->y = newEndY;
}

- (void)onDraw:(int)pageIndex inContext:(CGContextRef)context annot:(FSAnnot *)annot {
    if (_extensionsManager.currentAnnot == annot && pageIndex == annot.pageIndex && self.annotImage) {
        FSLine *lineAnnot = (FSLine *) annot;
        CGPoint startPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.startPoint ?: [lineAnnot getStartPoint] pageIndex:pageIndex];
        CGPoint endPoint = [_pdfViewCtrl convertPdfPtToPageViewPt:self.endPoint ?: [lineAnnot getEndPoint] pageIndex:pageIndex];
        CGFloat lineWidth = [Utility convertWidth:annot.lineWidth fromPageViewToPDF:_pdfViewCtrl pageIndex:pageIndex];

        CGRect rect = [_pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
        CGContextSaveGState(context);

        CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);
        CGContextTranslateCTM(context, 0, rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
        CGContextDrawImage(context, rect, [self.annotImage CGImage]);

        CGContextRestoreGState(context);

        UIImage *dragDot = [UIImage imageNamed:@"annotation_drag.png"];

        CGPoint dotStartPoint, dotEndPoint;
        [self getDotStartPoint:&dotStartPoint dotEndPoint:&dotEndPoint withStartPoint:startPoint endPoint:endPoint lineWidth:lineWidth];
        dotStartPoint.x -= dragDot.size.width / 2;
        dotStartPoint.y -= dragDot.size.height / 2;
        dotEndPoint.x -= dragDot.size.width / 2;
        dotEndPoint.y -= dragDot.size.height / 2;
        [dragDot drawAtPoint:dotStartPoint];
        [dragDot drawAtPoint:dotEndPoint];
        
        if ([[lineAnnot getIntent] isEqualToString:@"LineDimension"]){
            //Draw Distance Text
            NSMutableParagraphStyle* textStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
            textStyle.alignment = NSTextAlignmentLeft;
            
            NSDictionary* textFontAttributes = @{
                                                 NSFontAttributeName: [UIFont fontWithName: @"Helvetica" size: 12],
                                                 NSForegroundColorAttributeName: UIColor.redColor,
                                                 NSParagraphStyleAttributeName: textStyle
                                                 };
            
            dotStartPoint.y -= 10;
            
            NSString *measureRatio = lineAnnot ? [lineAnnot getMeasureRatio]:_extensionsManager.distanceUnit;
            float distance = [Utility getDistanceFromX:self.startPoint ?:[lineAnnot getStartPoint] toY:self.endPoint ?:[lineAnnot getEndPoint] withUnit:measureRatio];
            
            NSString *unitStr = lineAnnot ? [lineAnnot getMeasureUnit:0] : [_measureRatioInfo objectAtIndex:3];
            
            NSString *distanceContent = [NSString stringWithFormat:@"%.2f%@",distance,unitStr];
            [distanceContent drawAtPoint:dotStartPoint withAttributes:textFontAttributes];
        }
    }
}

- (CGPoint)rotateVec:(float)px py:(float)py ang:(float)ang isChlen:(BOOL)isChlen newLine:(float)newLen {
    CGPoint point = CGPointMake(0, 0);
    float vx = px * cosf(ang) - py * sinf(ang);
    float vy = px * sinf(ang) + py * cosf(ang);
    if (isChlen) {
        float d = sqrtf(vx * vx + vy * vy);
        vx = vx / d * newLen;
        vy = vy / d * newLen;
        point.x = vx;
        point.y = vy;
    }
    return point;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self dismissAnnotMenu];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self showAnnotMenu];
}
#pragma mark IPropertyBarListener

- (void)onPropertyBarDismiss {
    if (DEVICE_iPHONE && self.editAnnot && _extensionsManager.currentAnnot == self.editAnnot) {
        self.isShowStyle = NO;
        self.shouldShowPropety = NO;
        self.shouldShowMenu = YES;
        [self showAnnotMenu];
    }
}

- (void)onScrollViewWillBeginDragging:(UIScrollView *)dviewer {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndDragging:(UIScrollView *)dviewer willDecelerate:(BOOL)decelerate {
}

- (void)onScrollViewWillBeginDecelerating:(UIScrollView *)dviewer {
}

- (void)onScrollViewDidEndDecelerating:(UIScrollView *)dviewer {
    [self showAnnotMenu];
}

- (void)onScrollViewWillBeginZooming:(UIScrollView *)dviewer {
    [self dismissAnnotMenu];
}

- (void)onScrollViewDidEndZooming:(UIScrollView *)dviewer {
    [self showAnnotMenu];
}

- (void)showAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot) {
        CGRect rect = [self getRectForSelectedLine:(FSLine *) self.editAnnot];
        CGRect showRect = [_pdfViewCtrl convertPageViewRectToDisplayViewRect:rect pageIndex:self.editAnnot.pageIndex];

        if (self.shouldShowPropety) {
            [_extensionsManager.propertyBar showPropertyBar:showRect inView:[_pdfViewCtrl getDisplayView] viewsCanMove:[NSArray arrayWithObject:[_pdfViewCtrl getDisplayView]]];
        } else if (self.shouldShowMenu) {
            [_extensionsManager.menuControl setRect:showRect margin:0];
            [_extensionsManager.menuControl showMenu];
        }
    }
}

- (void)dismissAnnotMenu {
    if (_extensionsManager.currentAnnot == self.editAnnot) {
        if (_extensionsManager.menuControl.isMenuVisible) {
            [_extensionsManager.menuControl setMenuVisible:NO animated:YES];
        }
        if (_extensionsManager.propertyBar.isShowing) {
            [_extensionsManager.propertyBar dismissPropertyBar];
        }
    }
}

- (void)onDocWillClose:(FSPDFDoc *)document {
    if (self.replyVC) {
        [self.replyVC dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)onAnnotChanged:(FSAnnot *)annot property:(long)property from:(NSValue *)oldValue to:(NSValue *)newValue {
    if (annot == self.editAnnot && self.annotImage) {
        self.annotImage = [Utility getAnnotImage:self.editAnnot pdfViewCtrl:_pdfViewCtrl];
        int pageIndex = self.editAnnot.pageIndex;
        CGRect newRect = [_pdfViewCtrl convertPdfRectToPageViewRect:self.editAnnot.fsrect pageIndex:pageIndex];
        [_pdfViewCtrl refresh:CGRectInset(CGRectUnion(newRect, self.oldRect), -20, -20) pageIndex:pageIndex needRender:NO];
    }
}

@end
