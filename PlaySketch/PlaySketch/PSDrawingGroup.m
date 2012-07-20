/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSDrawingGroup.h"
#import "PSDrawingLine.h"
#import "PSHelpers.h"


@implementation PSDrawingGroup

@dynamic name;
@dynamic rootGroup;
@dynamic children;
@dynamic drawingLines;
@dynamic locationListAsData;
@dynamic parent;




- (void)addPosition:(SRTPosition)position
{
	// Find the index to insert it at
	int newIndex = 0;
	while (newIndex < locationCount && locationList[newIndex].frame < position.frame)
		newIndex++;
	
	
	//Overwrite an existing one if possible
	if(newIndex < locationCount && locationList[newIndex].frame == position.frame)
	{
		locationList[newIndex] = position;
	}
	else
	{
		// Expand our buffer if it is full
		if(locationBufferCount == locationCount)
		{
			int newBufferCount = locationBufferCount * 2; // Double each time
			locationList = (SRTPosition*)realloc(locationList, newBufferCount * sizeof(SRTPosition));
			locationBufferCount = newBufferCount;
		}
		
		//Move everything down!
		memmove(locationList + newIndex + 1, locationList + newIndex ,
			   (locationCount - newIndex)*sizeof(SRTPosition));
		
		//Write the new one
		locationList[newIndex] = position;
		locationCount++;
	}
}



/*
 This is called the first time our object is inserted into a store
 Create our transient C-style points here
 */
- (void)awakeFromInsert
{
	[super awakeFromInsert];
	[self copyToCache];
	currentSRTPosition = SRTPositionZero();
	currentSRTRate = SRTRateZero();
}


/*
 This is called when our object comes out of storage
 Copy our data into our cached c-arrays for faster access
 */
-(void)awakeFromFetch
{
	[super awakeFromFetch];
	[self copyToCache];
	currentSRTPosition = SRTPositionZero();
	currentSRTRate = SRTRateZero();
}


/*
 This is called after undo/redo types of events
 Copy our pointsAsData back into our points buffer after the change
 */
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	[super awakeFromSnapshotEvents:flags];
	[PSHelpers NYIWithmessage:@"drawinggroup awakeFromSnapshotEvents:"];
}


/*
 This is called when it is time to save this object
 Before the save, we copy the transient points data into the structure
 */
- (void)willSave
{
	[self copyFromCache];
}


/*
	Find the max and min points across our children
	This is not cached (maybe it should be if this is needed often?)
*/
- (CGRect)calculateFrame
{
	return [PSDrawingLine calculateFrameForLines:self.drawingLines];
}



-(void)copyToCache
{
	[PSHelpers assert:(locationList == nil) withMessage:@"should have no locationList"];
	
	if(self.locationListAsData == nil)
	{
		int STARTING_BUFFER_SIZE = 10;
		locationList = (SRTPosition*)malloc(sizeof(SRTPosition) * STARTING_BUFFER_SIZE);
		locationCount = 0;
		locationBufferCount = STARTING_BUFFER_SIZE;		
	}
	else
	{
		uint byteCount = self.locationListAsData.length;
		locationList = (SRTPosition*)malloc(byteCount);
		memcpy(locationList, self.locationListAsData.bytes, byteCount);
		locationCount = byteCount / sizeof(SRTPosition);
		locationBufferCount = locationCount;
	}
}


-(void)copyFromCache
{
	NSData* newLocationData = [NSData dataWithBytes:locationList length:( locationCount * sizeof(SRTPosition) )];
	
	// Only set a persisted property if it is different to prevent infinite recursion
	if ( ![newLocationData isEqualToData:self.locationListAsData] )
		self.locationListAsData = newLocationData;
}



@end
