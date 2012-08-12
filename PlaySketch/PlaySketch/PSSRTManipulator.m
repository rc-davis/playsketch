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
#import "PSHelpers.h"
#import <GLKit/GLKit.h> // for the math
#import <QuartzCore/QuartzCore.h>

@interface PSSRTManipulator ()
- (CGAffineTransform)incrementalTransformWithTouches:(NSSet *)touches;
@end


@implementation PSSRTManipulator
@synthesize delegate = _delegate;
@synthesize group = _group;


-(id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		// sensible defaults
		[self setApperanceIsSelected:YES isCharacter:NO isRecording:NO];
	}
	
	return self;
}

- (void)setApperanceIsSelected:(BOOL)selected isCharacter:(BOOL)character isRecording:(BOOL)recording
{
	UIColor* newBackground = [UIColor blackColor];
	
	if( selected && !character && !recording )
	{
		// Inital selection, yellow color
		newBackground = [UIColor colorWithRed:0.950 green:1.000 blue:0.045 alpha:0.5];
		
	}
	else if(!selected && !character && !recording)
	{
		// A zombie manipulator...
		newBackground = [UIColor blackColor];
	}
	else if( !selected && character && !recording )
	{
		// A character that isn't selected, grey background color
		newBackground = [UIColor colorWithRed:0.494 green:0.495 blue:0.470 alpha:0.2];
	}
	else if ( selected && character && !recording )
	{
		// A character that is selected but not recording, orange color
		newBackground = [UIColor colorWithRed:1.000 green:0.734 blue:0.116 alpha:0.5];

	}
	else if ( selected && character && recording )
	{
		// A character that is selected and in recording mode, red!
		newBackground = [UIColor colorWithRed:1.000 green:0.000 blue:0.000 alpha:0.5];

	}
	else
	{
		NSLog(@"selected? %d\tcharacter? %d\trecording? %d", selected, character, recording);
		[PSHelpers NYIWithmessage:@"This combination has not been considered..."];
	}
	self.backgroundColor = newBackground;
}


-(void)setFrame:(CGRect)frame
{
	/*	
		We are using the self.transform property to display the multi-touch 
		gestures that are scaling, rotating and translating this manipulator.
		To combine these three values and make the math easier, we are
		representing them as a CGAffineTransform, which is assigned to the
		manipulator's self.transform property.
	 
		A UIView's transform is always relative to the center-point of the view.
		(A rotation, for example, will happen about the center of the view)
		We want the PSDrawingGroups to share this definition of center-point,
		even as we translate the manipulator around.
		This is easiest if we do ALL translations of this manipulator by adjusting
		the self.transform property instead of the normal self.frame or self.center
		properties.
		To make this happen transparently, we're overriding the self.frame setter
		to center the view's frame on 0,0, then translate it using self.transform.
		
		This will also zero out any Scales and Rotates and return to identity.
	 
		If none of this makes any sense, read the UIView documenation on frame, 
		bounds, center, and transform:
		http://developer.apple.com/library/ios/#documentation/uikit/reference/uiview_class/uiview/uiview.html
	 */
	
	// Add some padding to the frame if necessary
	float MIN_FRAME_DIMENSION = 75.0; //Bigger than the recommended minimum touch target
	if(frame.size.width < MIN_FRAME_DIMENSION)
	{
		float deltaWidth = MIN_FRAME_DIMENSION - frame.size.width;
		frame.size.width += deltaWidth;
		frame.origin.x -= deltaWidth/2.0;
	}
	if(frame.size.height < MIN_FRAME_DIMENSION) //Recommended minimum touch target
	{
		float deltaHeight = MIN_FRAME_DIMENSION - frame.size.height;
		frame.size.height += deltaHeight;
		frame.origin.y -= deltaHeight/2.0;
	}
	
	
	CGRect frameAboutZero = CGRectMake(-frame.size.width/2.0, -frame.size.height/2.0,
									   frame.size.width, frame.size.height);
	CGPoint centerPoint = CGPointMake(frame.origin.x + frame.size.width/2.0,
									  frame.origin.y + frame.size.height/2.0);
	[super setFrame:frameAboutZero];	
	self.transform = CGAffineTransformMakeTranslation(centerPoint.x, centerPoint.y);
}


- (CGPoint)upperRightPoint
{
	return CGPointMake(CGRectGetMaxX(self.frame),
					   CGRectGetMinY(self.frame));
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(self.delegate)
		[self.delegate manipulatorDidStartInteraction:self];
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
	if (self.delegate)
		[self.delegate manipulatorDidStopInteraction:self];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (self.delegate)
		[self.delegate manipulatorDidStopInteraction:self];
	//TODO: should this be a 'manipulatorDidCancelInteraction:'?
}


/*
	Turns a set of touches from touchesMoved: into an affine transform representing
	the S,R,T change being made.
	Heavily borrowed from:
	https://github.com/erica/iphone-3.0-cookbook-/tree/master/C08-Gestures/14-Resize%20And%20Rotate
	(which is "heavily borrowed" from Apple sample code).
	Concatenating this with the view's current transform (self.transform) will
	properly update the the location of the view to respond to multi-touch
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
