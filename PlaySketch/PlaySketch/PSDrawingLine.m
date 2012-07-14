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
-(void)addPoint:(CGPoint)p
{
	PS_ASSERT(points != nil, @"Points cache should already be allocated before adding to it");
	
	// Expand our buffer if it is full
	if(pointBufferCount == pointCount)
	{
		NSLog(@"Reallocating points buffer for addPoint");
		int newBufferCount = pointBufferCount * 2; // Double each time
		points = (CGPoint*)realloc(points, newBufferCount * sizeof(CGPoint));
		pointBufferCount = newBufferCount;
	}
	
	points[pointCount] = p;
	pointCount++;
	
}


/*
 This is called when our object comes out of storage
 Copy our pointsAsData into our points buffer for faster access
*/
-(void)awakeFromFetch
{
	[super awakeFromFetch];
	NSLog(@"Line Awaking from fetch");
	[self copyPointsIntoObjectCache];	
}


/*
 This is called the first time our object is inserted into a store
 Create our transient C-style points here
*/
- (void)awakeFromInsert
{
	[super awakeFromInsert];
	NSLog(@"Line Awaking from insert");
	[self copyPointsIntoObjectCache];
}


/*
 This is called after undo/redo types of events
 Copy our pointsAsData back into our points buffer after the change
*/
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	NSLog(@"Line Awaking from snapshot event");
	[super awakeFromSnapshotEvents:flags];
	PS_NOT_YET_IMPLEMENTED();
}


/*
 This is called when it is time to save this object
 Before the save, we copy the transient points data into the structure
*/
- (void)willSave
{
	NSLog(@"Line preparing for save");
	[self copyPointsOutOfObjectCache];
}


-(void)copyPointsIntoObjectCache
{
	PS_ASSERT(points == nil, @"awakeFromFetch should have no value for points yet");
	
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


@end
