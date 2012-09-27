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
#import "PSDataModel.h"
#import "PSHelpers.h"

#define MAX_FOUNTAIN_WEIGHT 6.0
#define MAX_FOUNTAIN_SPEED_PX  25.0
#define INITIAL_FOUNTAIN_OFFSET 10.0
#define ERASER_RADIUS 40.0

@interface PSDrawingLine ()
{
	NSMutableData* _mutablePoints;
}
- (CGPoint*)mutablePointData;
- (void)addCircleAt:(CGPoint)p withSize:(CGFloat)size;
@end

@implementation PSDrawingLine
@dynamic pointsAsData;
@dynamic color;
@dynamic group;
@synthesize selectionHitCounts = _selectionHitCounts;
@synthesize penWeight = _penWeight;


-(CGPoint*)points
{
	if (_mutablePoints )
		return (CGPoint*)_mutablePoints.bytes;
	else
		return (CGPoint*)self.pointsAsData.bytes;
}

- (CGPoint*)mutablePointData
{
	if(_mutablePoints == nil)
		_mutablePoints = [NSMutableData dataWithData:self.pointsAsData];
	return [_mutablePoints mutableBytes];
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
	[self mutablePointData]; // Create our bytes
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
		if(self.penWeight > 0)
			[self addCircleAt:to withSize:self.penWeight];
		else
		{
			[self addPoint:to];
			[self addPoint:to];
		}
	}
	else
	{
		CGPoint fromTopLast = self.points[pointCount - 1];
		CGPoint fromBottomLast = self.points[pointCount - 2];
		CGPoint from = CGPointMake((fromTopLast.x + fromBottomLast.x)/2.0,
								   (fromTopLast.y + fromBottomLast.y)/2.0);
		

		// If the weight is -1, treat it like a fountain pen and vary the width
		float weightLast = self.penWeight;
		float weightNext = self.penWeight;
		if (self.penWeight < 0)
		{
			double speedPx = hypot(to.x - from.x, to.y - from.y);
			float speedPcnt = MIN(1.0, speedPx/MAX_FOUNTAIN_SPEED_PX);
			weightNext = MAX_FOUNTAIN_WEIGHT * ( 0.25 + 0.75*(1 - speedPcnt) );

			CGPoint lastPoint1 = self.points[self.pointCount - 1];
			CGPoint lastPoint2 = self.points[self.pointCount - 2];
			weightLast = hypotf(lastPoint1.x - lastPoint2.x, lastPoint1.y - lastPoint2.y)/2.0;
		}
		
		//Calculate the normal
		CGSize normal = CGSizeMake(to.y - from.y, - (to.x - from.x));
		double length = hypot(normal.width, normal.height);
		if (length < 1) return;
		CGSize normalLast = CGSizeMake(normal.width / length * weightLast,
										 normal.height / length * weightLast);
		CGSize normalNext = CGSizeMake(normal.width / length * weightNext,
									   normal.height / length * weightNext);
		

		//Calculate the four offset points
		CGPoint fromTop = CGPointMake(from.x + normalLast.width,
									  from.y + normalLast.height);
		CGPoint fromBottom = CGPointMake(from.x - normalLast.width,
										 from.y - normalLast.height);
		CGPoint toTop = CGPointMake(to.x + normalNext.width,
									to.y + normalNext.height);
		CGPoint toBottom = CGPointMake(to.x - normalNext.width,
									   to.y - normalNext.height);
		
		[self addPoint:fromBottom];
		[self addPoint:fromTop];
		[self addPoint:toBottom];
		[self addPoint:toTop];
		
	}
}

- (void)finishLine
{
	if(self.pointCount > 2 && self.penWeight > 0)
	{
		CGPoint p1 = self.points[self.pointCount - 1];
		CGPoint p2 = self.points[self.pointCount - 2];
		[self addCircleAt:CGPointMake( (p1.x + p2.x)/2.0, (p1.y + p2.y)/2.0)
				 withSize:self.penWeight];
	}
	else if (self.pointCount <= 5 && self.penWeight < 0)
	{
		CGPoint p1 = self.points[self.pointCount - 1];
		CGPoint p2 = self.points[self.pointCount - 2];
		[self addCircleAt:CGPointMake( (p1.x + p2.x)/2.0, (p1.y + p2.y)/2.0)
				 withSize:4.0];
	}
}

- (void)addCircleAt:(CGPoint)p withSize:(CGFloat)size
{
	[self addPoint:p];
	
	[self addPoint:CGPointMake(p.x - size, p.y)];
	[self addPoint:p];
	[self addPoint:CGPointMake(p.x - size/M_SQRT2, p.y - size/M_SQRT2)];
	
	[self addPoint:CGPointMake(p.x, p.y - size)];
	[self addPoint:p];
	[self addPoint:CGPointMake(p.x + size/M_SQRT2, p.y - size/M_SQRT2)];
	
	
	[self addPoint:CGPointMake(p.x + size, p.y)];
	[self addPoint:p];
	[self addPoint:CGPointMake(p.x + size/M_SQRT2, p.y + size/M_SQRT2)];
	
	
	[self addPoint:CGPointMake(p.x, p.y + size)];
	[self addPoint:p];
	[self addPoint:CGPointMake(p.x - size/M_SQRT2, p.y + size/M_SQRT2)];
	
	[self addPoint:CGPointMake(p.x - size, p.y)];
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

	int pointCount = self.pointCount;
	CGPoint* points = [self mutablePointData];
	for(int i = 0; i < pointCount; i++)
		points[i] = CGPointApplyAffineTransform(points[i], transform);
}


- (CGRect)boundingRect
{
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

- (BOOL)eraseAtPoint:(CGPoint)p
{
	// Go through points and look for ones to erase
	int pointCount = self.pointCount;
	CGPoint* points = [self mutablePointData];

	//look for data to discard at the start of the line
	int firstKeep = 0;
	while(firstKeep < pointCount && hypot(points[firstKeep].x - p.x, points[firstKeep].y - p.y) < ERASER_RADIUS)
			firstKeep++;
	
	//look for data to discard at the end of the line
	int lastKeep = pointCount - 1;
	while(lastKeep >= 0 && hypot(points[lastKeep].x - p.x, points[lastKeep].y - p.y) < ERASER_RADIUS)
			lastKeep--;

	// Trim the points
	if(lastKeep < firstKeep)
	{
		return YES;
	}
	else if(lastKeep < pointCount - 1 || firstKeep > 0)
	{
		NSMutableData* d = [NSMutableData dataWithBytes:&points[firstKeep]
												 length:(lastKeep - firstKeep + 1)*sizeof(CGPoint)];
		_mutablePoints = d;
		points = [_mutablePoints mutableBytes];
		pointCount = self.pointCount;
	}

	
	//Look for a point in the middle to use to split the line!
	int firstErase = 0;
	while(firstErase < pointCount &&
		  hypot(points[firstErase].x - p.x, points[firstErase].y - p.y) > ERASER_RADIUS)
		firstErase++;

	if (firstErase < pointCount)
	{
		// Make a new line with the remaining points
		PSDrawingLine* newLine = [PSDataModel newLineInGroup:self.group withWeight:self.penWeight];
		newLine.color = self.color;
		[newLine setMutablePoints: [NSMutableData dataWithBytes:&points[firstErase]
														 length:(self.pointCount - firstErase)*sizeof(CGPoint)]];

		// Technically, we should recurse in case there is more than one section that overlaps the eraser
		// But there's so many touchpoints coming in that we should just ignore it in favour of speed
		//[newLine eraseAtPoint:p];
		
		//Remove those points from this line's data
		NSMutableData* d = [NSMutableData dataWithBytes:points
												 length:firstErase*sizeof(CGPoint)];
		_mutablePoints = d;

	}
	
	
	return (self.pointCount < 10);
}


// This assumes p is already in the line's coordinate space
- (BOOL)hitsPoint:(CGPoint)p
{
	float HIT_DISTANCE = 20.0;
	CGPoint* points = self.points;
	int pointCount = self.pointCount;
	for (int i = 0; i < pointCount; i++) {
		CGPoint q = points[i];
		if(hypot(q.x - p.x, q.y - p.y) < HIT_DISTANCE)
			return YES;
	}
	return NO;
}


- (void)setMutablePoints:(NSMutableData*)newPoints
{
	_mutablePoints = newPoints;
	
}

- (void)doneMutatingPoints
{
	self.pointsAsData = _mutablePoints;;
}

@end
