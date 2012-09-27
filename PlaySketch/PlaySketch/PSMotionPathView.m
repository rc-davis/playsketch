/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSMotionPathView.h"
#import "PSDrawingGroup.h"
#import "PSAnimationRenderingController.h"
#import "PSGraphicConstants.h"

@implementation PSMotionPathView

- (void) awakeFromNib
{
	// We need to correct the coordinate system of this view to match the others
	// It should be centred on 0,0 (by offsetting its bounds)
	self.bounds = CGRectMake(-self.bounds.size.width/2.0,
							 -self.bounds.size.height/2.0,
							 self.bounds.size.width,
							 self.bounds.size.height);

	// We also need to fix up the frame, since we are the child of a view which
	// has also made these corrections already (this is hacky)
	self.frame = CGRectMake(-self.frame.size.width/2.0,
						   -self.frame.size.height/2.0,
							self.frame.size.width,
							self.frame.size.height);

}


- (void)drawRect:(CGRect)rect
{
	[argsToUIColor(MOTION_PATH_STROKE_COLOR) setStroke];
	[argsToUIColor(SELECTION_COLOR) setFill];

	// Go through all the nodes that are selected and draw a path for them
	// This isn't as terrible as this seems, since it is only called when something changes
	// We could be more efficient at the cost of a lot of added complexity
	[self.rootGroup applyToSelectedSubTrees:^(PSDrawingGroup *g) {
		
		// Create a Bezier Path to represent the group
		UIBezierPath* newPath = [UIBezierPath bezierPath];
		CGFloat lineDash[] = { 10.0f, 5.0f };
		[newPath setLineDash:lineDash count:2 phase:0];
		[newPath setLineCapStyle:kCGLineCapRound];
		
		// Pick a point (in the group's co-ordinates) to tranform into the parent co-ords
		CGPoint linePoint = CGPointMake(0,0);
		
		
		SRTPosition* positions = g.positions;
		int positionCount = g.positionCount;
		
		for (int i = 0; i < positionCount; i++)
		{
			CGAffineTransform transform = (SRTPositionToTransform(positions[i]));
			CGPoint transformedPoint = CGPointApplyAffineTransform(linePoint, transform);
			
			if( i == 0 )
				[newPath moveToPoint:transformedPoint];
			else
				[newPath addLineToPoint:transformedPoint];
			
			// Add a keyframe
			if(SRTKeyframeIsAny(positions[i].keyframeType))
			{
				float PADDING = 10.0;
				CGRect fixedRect = CGRectMake(transformedPoint.x - PADDING,
											  transformedPoint.y - PADDING,
											  2.0*PADDING, 2.0*PADDING);
				[[UIBezierPath bezierPathWithOvalInRect:fixedRect] fill];
			}
			
		}
		[newPath stroke];
	}];
	
	

}


- (void)refreshSelected
{
	[self setNeedsDisplay];
}

@end
