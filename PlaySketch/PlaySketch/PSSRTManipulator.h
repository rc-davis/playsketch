/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

@class PSDrawingGroup;


#import <UIKit/UIKit.h>

@protocol PSSRTManipulatoDelegate

- (void)manipulatorDidStartInteraction:(id)sender
						 willTranslate:(BOOL)isTranslating
							willRotate:(BOOL)isRotating
							 willScale:(BOOL)isScaling;

- (void)manipulator:(id)sender
	didTranslateByX:(float)dX
			   andY:(float)dY
		   rotation:(float)dRotation
			  scale:(float)dScale
	  isTranslating:(BOOL)isTranslating
		 isRotating:(BOOL)isRotating
		  isScaling:(BOOL)isScaling
	   timeDuration:(float)duration;

- (void)manipulatorDidStopInteraction:(id)sender
					   wasTranslating:(BOOL)isTranslating
						  wasRotating:(BOOL)isRotating
						   wasScaling:(BOOL)isScaling
						 withDuration:(float)duration;

@end


@interface PSSRTManipulator : UIView
@property(nonatomic,weak) id<PSSRTManipulatoDelegate> delegate;
@property(nonatomic,weak) PSDrawingGroup* group;
- (id)initAtLocation:(CGPoint)center;
- (CGPoint)upperRightPoint;
- (void)setApperanceIsSelected:(BOOL)selected isCharacter:(BOOL)character isRecording:(BOOL)recording;

@end
