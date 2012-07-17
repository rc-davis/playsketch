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
-(void)manipulator:(id)sender didUpdateToTransform:(CGAffineTransform)transform;
@end

@interface PSSRTManipulator : UIView

-(id)initWithFrame:(CGRect)frame;

@end
