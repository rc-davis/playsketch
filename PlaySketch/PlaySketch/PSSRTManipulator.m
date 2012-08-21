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
{
	UIBezierPath* _translatePath;
	UIBezierPath* _rotatePath;
	UIBezierPath* _scalePath;
	BOOL _isRotating;
	BOOL _isTranslating;
	BOOL _isScaling;
}
- (UIBezierPath*)buildTranslatePath;
- (UIBezierPath*)buildRotatePath;
- (UIBezierPath*)buildScalePath;
@end


@implementation PSSRTManipulator
@synthesize delegate = _delegate;
@synthesize group = _group;

-(id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		self.backgroundColor = [UIColor clearColor];
		_isRotating = NO;
		_isTranslating = NO;
		_isScaling = NO;
		_translatePath = [self buildTranslatePath];
		_rotatePath = [self buildRotatePath];
		_scalePath = [self buildScalePath];
	}
	
	return self;
}


- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, self.frame.size.width/2.0, self.frame.size.height/2.0);

	[[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:(_isScaling ? 1.0 : 0.6)] setFill];
	[_scalePath fill];
	
	[[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:(_isRotating ? 1.0 : 0.6)] setFill];
	[_rotatePath fill];

	[[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:(_isTranslating ? 1.0 : 0.6)] setFill];
	[_translatePath fill];
	
}



- (void)setApperanceIsSelected:(BOOL)selected isCharacter:(BOOL)character isRecording:(BOOL)recording
{
}



- (CGPoint)upperRightPoint
{
	return CGPointMake(CGRectGetMaxX(self.frame),
					   CGRectGetMinY(self.frame));
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//	if(self.delegate)
//		[self.delegate manipulatorDidStartInteraction:self];

	
	UITouch* t = [touches anyObject];
	CGPoint p = [t locationInView:self];
	p.x -= self.frame.size.width/2.0;
	p.y -= self.frame.size.height/2.0;
	
	if ([_scalePath containsPoint:p])
		 _isScaling = YES;
	else if([_rotatePath containsPoint:p])
		  _isRotating = YES;
	else if ([_translatePath containsPoint:p])
		_isTranslating = YES;
	
	[self setNeedsDisplay];

}

/*-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{		
	if(self.delegate)
		[self.delegate manipulator:self
					   didUpdateBy:incrementalT
					   toTransform:self.transform];

}
*/
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//	if (self.delegate)
//		[self.delegate manipulatorDidStopInteraction:self];
	
	_isRotating = NO;
	_isTranslating = NO;
	_isScaling = NO;
	[self setNeedsDisplay];
}
/*
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (self.delegate)
		[self.delegate manipulatorDidStopInteraction:self];
}
*/


- (UIBezierPath*)buildTranslatePath
{
	CGFloat T_WIDTH_2 = 45.0;
	CGFloat T_ARROW_2 = 20.0;
	CGFloat T_ARROW_START_2 = 50.0;
	CGFloat T_ARROWHEAD_2 = 25.0;
	
	UIBezierPath* p = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-T_WIDTH_2,
																		-T_WIDTH_2,
																		T_WIDTH_2*2.0,
																		T_WIDTH_2*2.0)];
	[p appendPath: [UIBezierPath bezierPathWithRect:CGRectMake(-T_ARROW_2,
															   -T_ARROW_START_2,
															   T_ARROW_2*2,
															   T_ARROW_START_2*2)]];
	[p appendPath: [UIBezierPath bezierPathWithRect:CGRectMake(-T_ARROW_START_2,
															   -T_ARROW_2,
															   T_ARROW_START_2*2,
															   T_ARROW_2*2)]];
	
	[p moveToPoint:CGPointMake(T_ARROW_START_2 + T_ARROWHEAD_2,0.0)];
	[p addLineToPoint:CGPointMake(T_ARROW_START_2, T_ARROWHEAD_2)];
	[p addLineToPoint:CGPointMake(T_ARROW_START_2, -T_ARROWHEAD_2)];
	[p addLineToPoint:CGPointMake(T_ARROW_START_2 + T_ARROWHEAD_2,0.0)];
	
	[p moveToPoint:CGPointMake(-T_ARROW_START_2 - T_ARROWHEAD_2,0.0)];
	[p addLineToPoint:CGPointMake(-T_ARROW_START_2, -T_ARROWHEAD_2)];
	[p addLineToPoint:CGPointMake(-T_ARROW_START_2, T_ARROWHEAD_2)];
	[p addLineToPoint:CGPointMake(-T_ARROW_START_2 - T_ARROWHEAD_2,0.0)];
	
	[p moveToPoint:CGPointMake(0.0, T_ARROW_START_2 + T_ARROWHEAD_2)];
	[p addLineToPoint:CGPointMake(T_ARROWHEAD_2, T_ARROW_START_2)];
	[p addLineToPoint:CGPointMake( -T_ARROWHEAD_2, T_ARROW_START_2)];
	[p addLineToPoint:CGPointMake(0.0, T_ARROW_START_2 + T_ARROWHEAD_2)];
	
	[p moveToPoint:CGPointMake(0.0, -T_ARROW_START_2 - T_ARROWHEAD_2)];
	[p addLineToPoint:CGPointMake(-T_ARROWHEAD_2, -T_ARROW_START_2)];
	[p addLineToPoint:CGPointMake(T_ARROWHEAD_2, -T_ARROW_START_2)];
	[p addLineToPoint:CGPointMake(0.0, -T_ARROW_START_2 - T_ARROWHEAD_2)];

	p.usesEvenOddFillRule = NO;
	return p;
}

- (UIBezierPath*)buildRotatePath
{
	CGFloat R_INNER_RAD = 70.0;
	CGFloat R_OUTER_RAD = 110.0;
	CGFloat R_ARROW_PAD = 15.0;

	UIBezierPath* p = [UIBezierPath bezierPath];
	[p addArcWithCenter:CGPointZero
						   radius:R_INNER_RAD
					   startAngle:M_PI
						 endAngle:M_PI + M_PI_4
						clockwise:NO];
	[p addArcWithCenter:CGPointZero
						   radius:R_OUTER_RAD
					   startAngle:M_PI + M_PI_4
						 endAngle:M_PI
						clockwise:YES];
	
	[p moveToPoint:CGPointMake(- (R_INNER_RAD - R_ARROW_PAD) / M_SQRT2,
										 - (R_INNER_RAD - R_ARROW_PAD) / M_SQRT2 )];
	[p addLineToPoint:CGPointMake(- (R_OUTER_RAD + R_ARROW_PAD) / M_SQRT2,
											- (R_OUTER_RAD + R_ARROW_PAD) / M_SQRT2 )];
	[p addLineToPoint:CGPointMake(- (R_OUTER_RAD + R_ARROW_PAD) / M_SQRT2,
											- (R_INNER_RAD - R_ARROW_PAD) / M_SQRT2 )];
	[p addLineToPoint:CGPointMake(- (R_INNER_RAD - R_ARROW_PAD) / M_SQRT2,
											- (R_INNER_RAD - R_ARROW_PAD) / M_SQRT2 )];
	
	return p;
}

- (UIBezierPath*)buildScalePath
{
	CGFloat S_INNER = 125.0;
	CGFloat S_LENGTH = 60.0;
	CGFloat S_WIDTH_2 = 20.0;
	CGFloat S_ARROWHEAD_2 = 45.0;

	UIBezierPath* p = [UIBezierPath bezierPath];
	UIBezierPath* scaleArrow = [UIBezierPath bezierPathWithRect:CGRectMake(-S_WIDTH_2,
																		   S_INNER,
																		   S_WIDTH_2*2.0,
																		   S_LENGTH)];

	[scaleArrow moveToPoint:CGPointMake(-S_ARROWHEAD_2, S_INNER + S_LENGTH)];
	[scaleArrow addLineToPoint:CGPointMake(0, S_INNER + S_LENGTH + S_ARROWHEAD_2)];
	[scaleArrow addLineToPoint:CGPointMake(S_ARROWHEAD_2, S_INNER + S_LENGTH)];
	[scaleArrow addLineToPoint:CGPointMake(-S_ARROWHEAD_2, S_INNER + S_LENGTH)];
	
	[scaleArrow applyTransform:CGAffineTransformMakeRotation(M_PI_4)];
	[p appendPath:scaleArrow];
	[scaleArrow applyTransform:CGAffineTransformMakeRotation(M_PI_2)];
	[p appendPath:scaleArrow];
	[scaleArrow applyTransform:CGAffineTransformMakeRotation(M_PI_2)];
	[p appendPath:scaleArrow];
	[scaleArrow applyTransform:CGAffineTransformMakeRotation(M_PI_2)];
	[p appendPath:scaleArrow];
	return p;
}

@end

