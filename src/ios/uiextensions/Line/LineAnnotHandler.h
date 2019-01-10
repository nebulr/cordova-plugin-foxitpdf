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

#import "PropertyBar.h"
#import "UIExtensionsManager+Private.h"
#import "UIExtensionsManager.h"
#import <FoxitRDK/FSPDFViewControl.h>

typedef enum {
    EDITANNOT_LINE_TYPE_UNKNOWN = -1,
    EDITANNOT_LINE_TYPE_START_POINT = 0,
    EDITANNOT_LINE_TYPE_END_POINT,
    EDITANNOT_LINE_TYPE_FULL,
} EDITANNOT_LINE_TYPE;

@interface LineAnnotHandler : NSObject <IAnnotHandler, IPropertyBarListener, IRotationEventListener, IGestureEventListener, IScrollViewEventListener, IAnnotPropertyListener, IDocEventListener> {
    EDITANNOT_LINE_TYPE _editType;
}

@property (nonatomic, strong) FSAnnot *editAnnot;
@property (nonatomic, strong) FSPointF *startPoint;
@property (nonatomic, strong) FSPointF *endPoint;
@property (nonatomic, strong) UIViewController *replyVC;

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager;

@end
