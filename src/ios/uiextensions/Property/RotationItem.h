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

#import "../Utility/Utility.h"
#import <Foundation/Foundation.h>
#import <UIKIt/UIKit.h>

@interface RotationItem : UIView

@property (nonatomic) int rotation;
//@property (nonatomic, assign) int opacity;
@property (nonatomic, copy) CallBackInt callback;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setSelected:(BOOL)selected;

@end
