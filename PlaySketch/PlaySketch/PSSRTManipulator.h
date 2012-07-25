/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#define PSSRT_BACKGROUND_UICOLOR [UIColor colorWithRed:1.000 green:0.490 blue:0.000 alpha:0.3]
#define PSSRT_BORDER_UICOLOR [UIColor colorWithRed:1.000 green:0.490 blue:0.000 alpha:1.000]
@class PSDrawingGroup;


#import <UIKit/UIKit.h>

@protocol PSSRTManipulatoDelegate
-(void)manipulator:(id)sender didUpdateBy:(CGAffineTransform)incrementalTransform toTransform:(CGAffineTransform)fullTransform;
@end

@interface PSSRTManipulator : UIView
@property(nonatomic,weak) id<PSSRTManipulatoDelegate> delegate;
@property(nonatomic,weak) PSDrawingGroup* group;
-(id)initWithFrame:(CGRect)frame;

@end
