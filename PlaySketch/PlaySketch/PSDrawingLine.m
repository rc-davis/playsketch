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


/* Private Interface */
@interface PSDrawingLine ()
-(void)copyPointsIntoObjectCache;
-(void)copyPointsOutOfObjectCache;
@end


@implementation PSDrawingLine
@dynamic pointsAsData;
@dynamic group;


/*
 Add a new point to the end of the current line
*/
-(void)addLineFrom:(CGPoint)from to:(CGPoint)to
{
	[PSHelpers assert:(points != nil) withMessage:@"Points cache should already be allocated"];
	
	// Expand our buffer if it is full
	if(pointBufferCount == pointCount)
	{
		NSLog(@"Reallocating points buffer for addPoint");
		int newBufferCount = pointBufferCount * 2; // Double each time
		points = (CGPoint*)realloc(points, newBufferCount * sizeof(CGPoint));
		pointBufferCount = newBufferCount;
	}
	
	points[pointCount] = to;
	pointCount++;
	
}

-(CGPoint*)points
{
	return points;
}

-(int)pointCount
{
	return pointCount;
}



/*
 This is called when our object comes out of storage
 Copy our pointsAsData into our points buffer for faster access
*/
-(void)awakeFromFetch
{
	[super awakeFromFetch];
	[self copyPointsIntoObjectCache];	
}


/*
 This is called the first time our object is inserted into a store
 Create our transient C-style points here
*/
- (void)awakeFromInsert
{
	[super awakeFromInsert];
	[self copyPointsIntoObjectCache];
}


/*
 This is called after undo/redo types of events
 Copy our pointsAsData back into our points buffer after the change
*/
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	[super awakeFromSnapshotEvents:flags];
	[PSHelpers NYIWithmessage:@"drawingline awakeFromSnapshotEvents:"];
}


/*
 This is called when it is time to save this object
 Before the save, we copy the transient points data into the structure
*/
- (void)willSave
{
	NSLog(@"will save line");
	[self copyPointsOutOfObjectCache];
}


-(void)copyPointsIntoObjectCache
{
	[PSHelpers assert:(points == nil) withMessage:@"awakeFromFetch should have no value for points yet"];
	
	if(self.pointsAsData == nil)
	{
		int STARTING_BUFFER_SIZE = 100;
		points = (CGPoint*)malloc(sizeof(CGPoint) * STARTING_BUFFER_SIZE);
		pointCount = 0;
		pointBufferCount = STARTING_BUFFER_SIZE;		
	}
	else
	{
		uint byteCount = self.pointsAsData.length;
		points = (CGPoint*)malloc(byteCount);
		memcpy(points, self.pointsAsData.bytes, byteCount);
		pointCount = byteCount / sizeof(CGPoint);
		pointBufferCount = pointCount;
	}
}


-(void)copyPointsOutOfObjectCache
{
	NSData* newPointsData = [NSData dataWithBytes:points length:( pointCount * sizeof(CGPoint) )];
	
	// Only set a persisted property if it is different to prevent infinite recursion
	if ( ![newPointsData isEqualToData:self.pointsAsData] )
		self.pointsAsData = newPointsData;
}

-(void)applyIncrementalTransform:(CGAffineTransform)transform
{
	for(int i = 0; i < pointCount; i++)
	{
		points[i] = CGPointApplyAffineTransform(points[i], transform);
	}
}


- (CGRect)calculateFrame
{
	CGPoint min = CGPointMake(1e100, 1e100);
	CGPoint max = CGPointMake(-1e100, -1e100);

	for(int i = 0; i < pointCount; i++)
	{
		min.x = MIN(min.x, points[i].x);
		min.y = MIN(min.y, points[i].y);
		max.x = MAX(max.x, points[i].x);
		max.y = MAX(max.y, points[i].y);
	}
	if(min.x > max.x) return CGRectNull;
	else return CGRectMake(min.x, min.y, (max.x - min.x), (max.y - min.y));
}
	
+(CGRect)calculateFrameForLines:(id<NSFastEnumeration>) enumerable
{
	CGPoint min = CGPointMake(1e100, 1e100);
	CGPoint max = CGPointMake(-1e100, -1e100);

	for (PSDrawingLine* line in enumerable)
	{
		CGRect lineFrame = [line calculateFrame];
		if(!CGRectIsNull(lineFrame))
		{
			min.x = MIN(min.x, CGRectGetMinX(lineFrame));
			min.y = MIN(min.y, CGRectGetMinY(lineFrame));
			max.x = MAX(max.x, CGRectGetMaxX(lineFrame));
			max.y = MAX(max.y, CGRectGetMaxY(lineFrame));
		}

	}
	if(min.x > max.x) return CGRectNull;
	else return CGRectMake(min.x, min.y, (max.x - min.x), (max.y - min.y));	
}


@end
