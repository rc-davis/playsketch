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


-(void)awakeFromFetch
{
	NSLog(@"Line Awaking from fetch");
	// This is called when our object comes out of storage
	// Copy our pointsAsData into our points buffer for faster access

	[self copyPointsIntoObjectCache];	
}


- (void)awakeFromInsert
{
	NSLog(@"Line Awaking from insert");
	// This is called the first time our object is inserted into a store
	// Create our transient C-style points here

	[self copyPointsIntoObjectCache];
}


- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	NSLog(@"Line Awaking from snapshot event");
	
	// This is called after undo/redo types of events
	// Copy our pointsAsData back into our points buffer after the change
	
	PS_NOT_YET_IMPLEMENTED();
}


- (void)willSave
{
	NSLog(@"Line preparing for save");

	// This is called when it is time to save this object
	// Before the save, we copy the transient points data into the structure
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
		pointBufferSize = STARTING_BUFFER_SIZE;		
	}
	else
	{
		points = (CGPoint*)malloc( self.pointsAsData.length );
		pointCount = self.pointsAsData.length / sizeof(CGPoint);
		pointBufferSize = pointCount;
		[self.pointsAsData getBytes:&points length:self.pointsAsData.length];
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
