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

@interface PSDrawingGroup ()
{
	NSMutableData* _mutablePositionsAsData;
}
@end

@implementation PSDrawingGroup

@dynamic name;
@dynamic rootGroup;
@dynamic children;
@dynamic drawingLines;
@dynamic positionsAsData;
@dynamic parent;



- (void)addPosition:(SRTPosition)position
{
	// Get a handle to some mutable data
	int currentPositionCount = self.positionCount;
	SRTPosition* currentPositions;
	if ( _mutablePositionsAsData == nil )
		_mutablePositionsAsData = [NSMutableData dataWithData:self.positionsAsData];
	currentPositions = (SRTPosition*)_mutablePositionsAsData.bytes;	
	
	
	// Find the index to insert it at
	int newIndex = 0;
	while (newIndex < currentPositionCount && 
		   currentPositions[newIndex].frame < position.frame)
		newIndex++;
	

	BOOL overwriting = newIndex < currentPositionCount && 
						currentPositions[newIndex].frame == position.frame;

	//Make space for the new entry if necessary
	if(!overwriting)
	{
		[_mutablePositionsAsData increaseLengthBy:sizeof(SRTPosition)];
		currentPositions = (SRTPosition*)_mutablePositionsAsData.bytes;

		//Move everything down!
		memmove(currentPositions + newIndex + 1, 
				currentPositions + newIndex ,
				(currentPositionCount - newIndex)*sizeof(SRTPosition));
	}
		
	//Write the new one
	currentPositions[newIndex] = position;
}

- (SRTPosition*)positions
{
	if (_mutablePositionsAsData != nil)
		return (SRTPosition*)_mutablePositionsAsData.bytes;
	else
		return (SRTPosition*)self.positionsAsData.bytes;

}

- (int)positionCount
{
	if (_mutablePositionsAsData != nil)
		return _mutablePositionsAsData.length / sizeof(SRTPosition);
	else
		return self.positionsAsData.length / sizeof(SRTPosition);
}


/*
 This is called the first time our object is inserted into a store
 Create our transient C-style points here
 */
- (void)awakeFromInsert
{
	[super awakeFromInsert];
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
	if (_mutablePositionsAsData != nil)
	{
		self.positionsAsData = _mutablePositionsAsData;
		_mutablePositionsAsData = nil;
	}
}


/*
	Find the max and min points across our children
	This is not cached (maybe it should be if this is needed often?)
*/
- (CGRect)calculateFrame
{
	return [PSDrawingLine calculateFrameForLines:self.drawingLines];
}


@end
