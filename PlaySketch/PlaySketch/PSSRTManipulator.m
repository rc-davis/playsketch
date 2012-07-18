/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSSRTManipulator.h"
#import <GLKit/GLKit.h> // for the math
#import <QuartzCore/QuartzCore.h>

@interface PSSRTManipulator ()
- (CGAffineTransform)incrementalTransformWithTouches:(NSSet *)touches;
@end


@implementation PSSRTManipulator
@synthesize delegate = _delegate;


-(id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		self.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.5];
	}
	
	return self;
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Consume the event so it isn't passed up the chain
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{		
	CGAffineTransform incrementalT = [self incrementalTransformWithTouches:event.allTouches];
	self.transform = CGAffineTransformConcat(self.transform, incrementalT);
	
	if(self.delegate)
		[self.delegate manipulator:self
					   didUpdateBy:incrementalT
					   toTransform:self.transform];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	
}

/*
	Turns a set of touches from touchesMoved: into an affine transform representing
	the S,R,T change being made.
	Heavily borrowed from:
	https://github.com/erica/iphone-3.0-cookbook-/tree/master/C08-Gestures/14-Resize%20And%20Rotate
	(which is "heavily borrowed" from Apple sample code)
	concatenating this with the view's current transform will update properly
*/
- (CGAffineTransform)incrementalTransformWithTouches:(NSSet *)touches 
{
	NSInteger numTouches = [touches count];
	if (numTouches == 0)
	{
		// If there are no touches, simply return identify transform.
		return CGAffineTransformIdentity;
	}
	else if (numTouches == 1)
	{
		// A single touch is a simple translation
		UITouch *touch = [touches anyObject];
		CGPoint beginPoint = [touch previousLocationInView:self.superview];
		CGPoint currentPoint = [touch locationInView:self.superview];
		return CGAffineTransformMakeTranslation(currentPoint.x - beginPoint.x,
												currentPoint.y - beginPoint.y);
	}
	else
	{
		//With two or more touches, just grab the first two
		
		UITouch *touch1 = [[touches allObjects] objectAtIndex:0];
		UITouch *touch2 = [[touches allObjects] objectAtIndex:1];
	
		CGPoint beginPoint1 = [touch1 previousLocationInView:self.superview];
		CGPoint currentPoint1 = [touch1 locationInView:self.superview];
		CGPoint beginPoint2 = [touch2 previousLocationInView:self.superview];
		CGPoint currentPoint2 = [touch2 locationInView:self.superview];

		double layerX = self.center.x;
		double layerY = self.center.y;

		double x1 = beginPoint1.x - layerX;
		double y1 = beginPoint1.y - layerY;
		double x2 = beginPoint2.x - layerX;
		double y2 = beginPoint2.y - layerY;
		double x3 = currentPoint1.x - layerX;
		double y3 = currentPoint1.y - layerY;
		double x4 = currentPoint2.x - layerX;
		double y4 = currentPoint2.y - layerY;

		// Solve the system:
		//   [a b t1, -b a t2, 0 0 1] * [x1, y1, 1] = [x3, y3, 1]
		//   [a b t1, -b a t2, 0 0 1] * [x2, y2, 1] = [x4, y4, 1]

		double D = (y1-y2)*(y1-y2) + (x1-x2)*(x1-x2);
		if (D < 0.1)
		{
			//Treat the degenerate case like a translation
			return CGAffineTransformMakeTranslation(x3-x1, y3-y1);
		}

		double a = (y1-y2)*(y3-y4) + (x1-x2)*(x3-x4);
		double b = (y1-y2)*(x3-x4) - (x1-x2)*(y3-y4);
		double tx = (y1*x2 - x1*y2)*(y4-y3) - (x1*x2 + y1*y2)*(x3+x4) + 
					x3*(y2*y2 + x2*x2) + x4*(y1*y1 + x1*x1);
		double ty = (x1*x2 + y1*y2)*(-y4-y3) + (y1*x2 - x1*y2)*(x3-x4) + 
					y3*(y2*y2 + x2*x2) + y4*(y1*y1 + x1*x1);

		return CGAffineTransformMake(a/D, -b/D, b/D, a/D, tx/D, ty/D);
	}
}



@end
