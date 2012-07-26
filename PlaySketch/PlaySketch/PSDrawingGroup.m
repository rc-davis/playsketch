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
@dynamic explicitCharacter;
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
		   currentPositions[newIndex].timeStamp < position.timeStamp)
		newIndex++;
	

	BOOL overwriting = newIndex < currentPositionCount && 
						currentPositions[newIndex].timeStamp == position.timeStamp;

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


- (void)getStateAtTime:(float)time
			  position:(SRTPosition*)pPosition
				  rate:(SRTRate*)pRate
		   helperIndex:(int*)pIndex
{
	int positionCount = self.positionCount;
	SRTPosition* positions = self.positions;
	SRTPosition resultPosition;
	SRTRate resultRate;
	int resultIndex;
	
	if ( positionCount == 0 )
	{
		resultPosition = SRTPositionZero();
		resultRate = SRTRateZero();
		resultIndex = -1;
	}
	else
	{
	
		// find i that upper-bounds our requested time
		int i = 0;
		while( i + 1 < positionCount && positions[i].timeStamp < time)
			i++;
		
		if(positions[i].timeStamp == time)
		{
			// If we are right on a position keyframe, return that keyframe
			// Interpolate the Rate if there is a following keyframe to interpolate to
			resultPosition = positions[i];
			resultRate = (i + 1 < positionCount) ?	SRTRateInterpolate(positions[i], positions[i+1]) :
													SRTRateZero();
			resultIndex = i;
		}
		else if( (positions[i].timeStamp > time && i == 0 ) ||
				 (positions[i].timeStamp < time && i == positionCount - 1) )
		{
			// If we are before the first keyframe or after the last keyframe,
			// return the current keyframe and set no rate of motion
			resultPosition = positions[i];
			resultRate = SRTRateZero();
			resultIndex = i;
		}
		else
		{
			// Otherwise, we are between two keyframes, so just interpolation the
			// position and the rate of motion
			resultPosition = SRTPositionInterpolate(time, positions[i-1], positions[i]);
			resultRate = SRTRateInterpolate(positions[i-1], positions[i]);
			resultIndex = i - 1;
		}
	}
	
	//Return results
	if(pPosition) *pPosition = resultPosition;
	if(pRate) *pRate = resultRate;
	if(pIndex) *pIndex = resultIndex;

}


- (CGAffineTransform)currentAffineTransform
{
	return SRTPositionToTransform(currentSRTPosition);
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


- (void)applyTransform:(CGAffineTransform)transform
{
	/*	Brute-force adjusting the points of the lines in this group
		Very slow and destructive to the original point information.
		Use sparingly, only to manipulate the basic data and not 
		just to adjust the display of a group.
	*/
	
	for (PSDrawingLine* line in self.drawingLines)
		[line applyTransform:transform];
	
	for (PSDrawingGroup* group in self.children)
		[group applyTransform:transform];
}


- (CGRect)boundingRect
{
	//TODO: WE SHOULD BE CACHING THIS INSTEAD OF BRUTE-FORCING IT
	if ( self.drawingLines.count == 0 )
		return CGRectNull;
	
	CGPoint min = CGPointMake(1e100, 1e100);
	CGPoint max = CGPointMake(-1e100, -1e100);
	for (PSDrawingLine* line in self.drawingLines)
	{
		CGRect lineRect = [line boundingRect];
		min.x = MIN(min.x, CGRectGetMinX(lineRect));
		min.y = MIN(min.y, CGRectGetMinY(lineRect));
		max.x = MAX(max.x, CGRectGetMaxX(lineRect));
		max.y = MAX(max.y, CGRectGetMaxY(lineRect));
	}
	return CGRectMake(min.x, min.y, max.x - min.x, max.y - min.y);
}

@end
