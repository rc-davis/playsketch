/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSKeyframeView.h"
#import "PSDataModel.h"
#import <QuartzCore/QuartzCore.h>
#import "PSGraphicConstants.h"


/* Private helper class for doing the drawing */
@interface PSKeyframeView ()
//@property(nonatomic,retain)CALayer* allKeyframeLayer;
//@property(nonatomic,retain)CALayer* selectedKeyframeLayer;
@end

@implementation PSKeyframeView


- (void)awakeFromNib
{
}

- (void)drawRect:(CGRect)rect
{
	// Collect all of the x-values for keyframes in a set to avoid duplicates
	NSMutableSet* xOffsetsSelected = [NSMutableSet set];
	NSMutableSet* xOffsetsUnselected = [NSMutableSet set];
	
	[self.rootGroup applyToAllSubTrees:^(PSDrawingGroup *g, BOOL subtreeSelected) {
		for(int i = 0; i < g.positionCount; i++)
		{
			SRTPosition p = g.positions[i];
			if(SRTKeyframeIsAny(p.keyframeType))
			{
				float xVal = [self.slider xOffsetForTime:p.timeStamp];
				if(subtreeSelected)
					[xOffsetsSelected addObject:[NSNumber numberWithFloat:xVal]];
				else
					[xOffsetsUnselected addObject:[NSNumber numberWithFloat:xVal]];
			}
		}
	}];
	
	
	// Draw them all
	[self drawKeyframes:xOffsetsUnselected withColor:TIMELINE_KEYFRAME_UNSELECTED_UICOLOR];
	[self drawKeyframes:xOffsetsSelected withColor:argsToUIColor(SELECTION_COLOR)];
	
}

- (void)drawKeyframes:(NSSet*)xOffsets withColor:(UIColor*)color
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, color.CGColor);
	float keyframeWidth = 0.9*(self.frame.size.width)/(self.slider.maximumValue*POSITION_FPS);
	CGRect r = CGRectMake(0, 0, keyframeWidth, self.frame.size.height);
	for (NSNumber* x in xOffsets)
	{
		r.origin.x = x.floatValue - r.size.width/2.0;
		CGContextFillRect (context, r);
	}
}

- (void)refreshAll
{
	[self setNeedsDisplay];
}

@end
