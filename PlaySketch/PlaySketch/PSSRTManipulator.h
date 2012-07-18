/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <UIKit/UIKit.h>

@protocol PSSRTManipulatoDelegate
-(void)manipulator:(id)sender didUpdateBy:(CGAffineTransform)incrementalTransform toTransform:(CGAffineTransform)fullTransform;
@end

@interface PSSRTManipulator : UIView
@property(nonatomic,weak) id<PSSRTManipulatoDelegate> delegate;
-(id)initWithFrame:(CGRect)frame;

@end
