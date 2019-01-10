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

#import "../Common/UIExtensionsSharedHeader.h"

@protocol IHandlerEventListener <NSObject>

- (void)onToolHandlerChanged:(id<IToolHandler>)lastTool currentTool:(id<IToolHandler>)currentTool;

@end

@interface SignatureModule : NSObject <IDocEventListener, IToolEventListener, IStateChangeListener, IModule>

- (instancetype)initWithUIExtensionsManager:(UIExtensionsManager *)extensionsManager;

@end
