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

#define EXPANDED_WIDTH_2 110.0
#define SHRUNK_WIDTH_2 40.0
#define GROUPBUTTON_PADDING 30.0


@interface PSSRTManipulator ()
{
	UIBezierPath* _translatePath;
	UIBezierPath* _rotatePath;
	UIBezierPath* _scalePath;
	BOOL _isRotating;
	BOOL _isTranslating;
	BOOL _isScaling;
	NSTimeInterval _lastTimeStamp;
	
}
- (UIBezierPath*)buildTranslatePath;
- (UIBezierPath*)buildRotatePath;
- (UIBezierPath*)buildScalePath;
@end


@implementation PSSRTManipulator
@synthesize delegate = _delegate;

- (id)initAtLocation:(CGPoint)center
{
	CGRect frame = CGRectMake(center.x - EXPANDED_WIDTH_2,
							  center.y - EXPANDED_WIDTH_2,
							  2*EXPANDED_WIDTH_2,
							  2*EXPANDED_WIDTH_2);
	
	if (self = [super initWithFrame:frame])
	{
		self.backgroundColor = [UIColor yellowColor];
		_isRotating = NO;
		_isTranslating = NO;
		_isScaling = NO;
		_translatePath = [self buildTranslatePath];
		_rotatePath = [self buildRotatePath];
		_scalePath = [self buildScalePath];
	}
	
	return self;
}

- (void)setGroupButtons:(UIView *)groupButtons
{
	if(_groupButtons)
		[_groupButtons removeFromSuperview];

	
	if(groupButtons)
	{
		CGRect newOwnFrame = self.frame;
		newOwnFrame.size.width = 2.0*(EXPANDED_WIDTH_2 + GROUPBUTTON_PADDING + groupButtons.frame.size.width);
		self.frame = newOwnFrame;

		[self addSubview:groupButtons];
		CGRect newFrame = groupButtons.frame;
		newFrame.origin.x = groupButtons.frame.size.width + EXPANDED_WIDTH_2*2.0 + GROUPBUTTON_PADDING*2.0;
		newFrame.origin.y = 0;
		groupButtons.frame = newFrame;
		
	}
	
	_groupButtons = groupButtons;

}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, self.frame.size.width/2.0, self.frame.size.height/2.0);
	
	if(_isScaling)
	{
		[[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.2] setFill];
		[_scalePath fill];
	}
	else if( _isRotating)
	{
		[[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.2] setFill];
		[_rotatePath fill];
	}
	else if( _isTranslating)
	{
		[[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.2] setFill];
		[_translatePath fill];
	}
	else
	{
		[[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5] setFill];
		[_scalePath fill];
		
		[[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.5] setFill];
		[_rotatePath fill];

		[[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.5] setFill];
		[_translatePath fill];
	}
}



- (CGPoint)upperRightPoint
{
	return CGPointMake(CGRectGetMaxX(self.frame),
					   CGRectGetMinY(self.frame));
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* t = [touches anyObject];
	CGPoint p = [t locationInView:self];
	_lastTimeStamp = t.timestamp;
	p.x -= self.frame.size.width/2.0;
	p.y -= self.frame.size.height/2.0;
	
	if ([_scalePath containsPoint:p])
		 _isScaling = YES;
	else if([_rotatePath containsPoint:p])
		  _isRotating = YES;
	else if ([_translatePath containsPoint:p])
		_isTranslating = YES;

	if(self.delegate)
		[self.delegate manipulatorDidStartInteraction:self
										willTranslate:_isTranslating
										   willRotate:_isRotating
											willScale:_isScaling];
	
	[self setNeedsDisplay];
	self.groupButtons.hidden = YES;

}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* t = [touches anyObject];
	CGPoint p = [t locationInView:self];
	CGPoint pPrevious = [t previousLocationInView:self];

	NSTimeInterval timeDuration = t.timestamp - _lastTimeStamp;
	_lastTimeStamp = t.timestamp;

	
	// Fix up to treat the center as (0,0)
	p.x -= self.frame.size.width/2.0;
	p.y -= self.frame.size.height/2.0;
	pPrevious.x -= self.frame.size.width/2.0;
	pPrevious.y -= self.frame.size.height/2.0;


	// Figure out how we've changed!
	
	float dX = 0;
	float dY = 0;
	if (_isTranslating)
	{
		dX = (p.x - pPrevious.x);
		dY = (p.y - pPrevious.y);
		self.center = CGPointMake(self.center.x + dX, self.center.y + dY);
	}
	
	float dRotation = 0;
	if (_isRotating)
	{
		// Calculate our change in angles
		float anglePrevious = atan2f(pPrevious.y, pPrevious.x);
		float angleNew = atan2f(p.y, p.x);
		dRotation = angleNew - anglePrevious;
		
		// Clean up angle to assume it is the short way around the circle
		if ( dRotation > M_PI ) dRotation -= 2*M_PI;
		if ( dRotation < -M_PI ) dRotation += 2*M_PI;
		
		//[_rotatePath applyTransform:CGAffineTransformMakeRotation(dRotation)];
		//[self setNeedsDisplay];
	}

	float dScale = 1;
	if (_isScaling)
	{
		float distancePrevious = hypotf(pPrevious.x, pPrevious.y);
		float distanceNew = hypotf(p.x, p.y);
		[PSHelpers assert:(distancePrevious != 0) withMessage:@"Divide by zero in scaling calculation"];
		dScale = distanceNew / distancePrevious;
	}
	
	// Inform the delegate
	if(self.delegate)
		[self.delegate manipulator:self
				   didTranslateByX:dX
							  andY:dY
						  rotation:dRotation
							 scale:dScale
					 isTranslating:_isTranslating
						isRotating:_isRotating
						 isScaling:_isScaling
					  timeDuration:timeDuration];


}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* t = [touches anyObject];

	if (self.delegate)
		[self.delegate manipulatorDidStopInteraction:self
									  wasTranslating:_isTranslating
										 wasRotating:_isRotating
										  wasScaling:_isScaling
										withDuration:t.timestamp - _lastTimeStamp];
	
	_isRotating = NO;
	_isTranslating = NO;
	_isScaling = NO;
	_lastTimeStamp = 0;
	
	[self setNeedsDisplay];
	self.groupButtons.hidden = NO;
}


-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* t = [touches anyObject];
	
	if (self.delegate)
		[self.delegate manipulatorDidStopInteraction:self
									  wasTranslating:_isTranslating
										 wasRotating:_isRotating
										  wasScaling:_isScaling
										withDuration:t.timestamp - _lastTimeStamp];
	_isRotating = NO;
	_isTranslating = NO;
	_isScaling = NO;
	_lastTimeStamp = 0;
	
	[self setNeedsDisplay];
	self.groupButtons.hidden = NO;
}


- (UIBezierPath*)buildTranslatePath
{
	CGFloat T_WIDTH_2 = EXPANDED_WIDTH_2 * 0.28;
	CGFloat T_ARROW_2 = EXPANDED_WIDTH_2 * 0.12;
	CGFloat T_ARROW_START_2 = EXPANDED_WIDTH_2 * 0.31;
	CGFloat T_ARROWHEAD_2 = EXPANDED_WIDTH_2 * 0.15;
	
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
	CGFloat R_INNER_RAD = EXPANDED_WIDTH_2 * 0.43;
	CGFloat R_OUTER_RAD = EXPANDED_WIDTH_2 * 0.67;
	CGFloat R_ARROW_PAD = EXPANDED_WIDTH_2 * 0.09;

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
	CGFloat S_INNER = EXPANDED_WIDTH_2 * 0.76;
	CGFloat S_LENGTH = EXPANDED_WIDTH_2 * 0.37;
	CGFloat S_WIDTH_2 = EXPANDED_WIDTH_2 * 0.12;
	CGFloat S_ARROWHEAD_2 = EXPANDED_WIDTH_2 * 0.28;

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

