/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSDrawingLine.h"
#import "PSDrawingGroup.h"
#import "PSHelpers.h"

#define OFFSET_DISTANCE 4.0


@interface PSDrawingLine ()
{
	NSMutableData* _mutablePoints;
}
- (void)addCircleAt:(CGPoint)p;
@end

@implementation PSDrawingLine
@dynamic pointsAsData;
@dynamic color;
@dynamic group;
@synthesize selectionHitCounts = _selectionHitCounts;


-(CGPoint*)points
{
	if (_mutablePoints )
		return (CGPoint*)_mutablePoints.bytes;
	else
		return (CGPoint*)self.pointsAsData.bytes;
}

-(int)pointCount
{
	if ( _mutablePoints )
		return _mutablePoints.length / sizeof(CGPoint);
	else
		return self.pointsAsData.length / sizeof(CGPoint);
}


/*
 Add a new point to the current line
*/
-(void)addPoint:(CGPoint)p
{
	if (_mutablePoints == nil)
		_mutablePoints = [NSMutableData dataWithData:self.pointsAsData];
	
	[_mutablePoints appendBytes:&p length:sizeof(CGPoint)];
}


/*
 Add a new line segment starting at the last point
 This uses some interpolation logic to achieve a constant frequency of points
 */
-(void)addLineTo:(CGPoint)to
{
	int pointCount = self.pointCount;
	// Deal with the case where we have no 'from' point
	if(pointCount < 2)
	{
		[self addCircleAt:to];
	}
	else
	{
		CGPoint fromTopLast = self.points[pointCount - 1];
		CGPoint fromBottomLast = self.points[pointCount - 2];
		CGPoint from = CGPointMake((fromTopLast.x + fromBottomLast.x)/2.0,
								   (fromTopLast.y + fromBottomLast.y)/2.0);
		
		
		//Calculate the normal
		CGSize normal = CGSizeMake(to.y - from.y, - (to.x - from.x));
		double length = hypot(normal.width, normal.height);
		if (length < 1) return;
		CGSize normalScaled = CGSizeMake(normal.width / length * OFFSET_DISTANCE,
										 normal.height / length * OFFSET_DISTANCE);
		

		//Calculate the four offset points
		CGPoint fromTop = CGPointMake(from.x + normalScaled.width,
									  from.y + normalScaled.height);
		CGPoint fromBottom = CGPointMake(from.x - normalScaled.width,
										 from.y - normalScaled.height);
		CGPoint toTop = CGPointMake(to.x + normalScaled.width,
									to.y + normalScaled.height);
		CGPoint toBottom = CGPointMake(to.x - normalScaled.width,
									   to.y - normalScaled.height);
		
		[self addPoint:fromBottom];
		[self addPoint:fromTop];
		[self addPoint:toBottom];
		[self addPoint:toTop];
		
		//Try out something like this:use the 'speed' to determine the offsetdistance!
		/*
		double speedPx = hypot(to.x - from.x, to.y - from.y);
		float speedPcnt = MIN(1.0, speedPx/50.0);
		
		OFFSET_DISTANCE = OFFSET_DISTANCE * ( 0.25 + 0.75*(1 - speedPcnt) );
		*/
	}
}

- (void)finishLine
{
	if(self.pointCount > 2)
	{
		CGPoint p1 = self.points[self.pointCount - 1];
		CGPoint p2 = self.points[self.pointCount - 2];
		[self addCircleAt:CGPointMake( (p1.x + p2.x)/2.0, (p1.y + p2.y)/2.0)];
		NSLog(@"adding a last point");
	}
}

- (void)addCircleAt:(CGPoint)p
{
	[self addPoint:CGPointMake(p.x - OFFSET_DISTANCE, p.y)];
	[self addPoint:p];
	[self addPoint:CGPointMake(p.x - OFFSET_DISTANCE/M_SQRT2, p.y - OFFSET_DISTANCE/M_SQRT2)];
	
	[self addPoint:CGPointMake(p.x, p.y - OFFSET_DISTANCE)];
	[self addPoint:p];
	[self addPoint:CGPointMake(p.x + OFFSET_DISTANCE/M_SQRT2, p.y - OFFSET_DISTANCE/M_SQRT2)];
	
	
	[self addPoint:CGPointMake(p.x + OFFSET_DISTANCE, p.y)];
	[self addPoint:p];
	[self addPoint:CGPointMake(p.x + OFFSET_DISTANCE/M_SQRT2, p.y + OFFSET_DISTANCE/M_SQRT2)];
	
	
	[self addPoint:CGPointMake(p.x, p.y + OFFSET_DISTANCE)];
	[self addPoint:p];
	[self addPoint:CGPointMake(p.x - OFFSET_DISTANCE/M_SQRT2, p.y + OFFSET_DISTANCE/M_SQRT2)];
	
	[self addPoint:CGPointMake(p.x - OFFSET_DISTANCE, p.y)];
	[self addPoint:p];
	[self addPoint:p];
}

- (void)willSave
{
	if (_mutablePoints != nil)
	{
		self.pointsAsData = _mutablePoints;
		_mutablePoints = nil;
	}
}


- (void)applyTransform:(CGAffineTransform)transform
{
	if (_mutablePoints == nil)
		_mutablePoints = [NSMutableData dataWithData:self.pointsAsData];
	
	int pointCount = self.pointCount;
	CGPoint* points = (CGPoint*)_mutablePoints.bytes;
	for(int i = 0; i < pointCount; i++)
		points[i] = CGPointApplyAffineTransform(points[i], transform);
}


- (CGRect)boundingRect
{
	//TODO: WE SHOULD BE CACHING THIS INSTEAD OF BRUTE-FORCING IT
	int pointCount = self.pointCount;
	CGPoint* points = self.points;

	if ( pointCount < 1 )
		return CGRectNull;

	CGPoint min = CGPointMake(1e100, 1e100);
	CGPoint max = CGPointMake(-1e100, -1e100);
	for(int i = 0; i < pointCount; i++)
	{
		min.x = MIN(min.x, points[i].x);
		min.y = MIN(min.y, points[i].y);
		max.x = MAX(max.x, points[i].x);
		max.y = MAX(max.y, points[i].y);
	}
	return CGRectMake(min.x, min.y, max.x - min.x, max.y - min.y);
}

- (void)prepareForSelection
{
	if(self.selectionHitCounts)
		free(self.selectionHitCounts);
	self.selectionHitCounts = (int*)calloc(self.pointCount, sizeof(int));
}

@end
