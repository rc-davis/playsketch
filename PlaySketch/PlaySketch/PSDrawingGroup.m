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
#import "PSDataModel.h"
#import "PSHelpers.h"
#import "PSRecordingSession.h"

@interface PSDrawingGroup ()
{
	NSMutableData* _mutablePositionsAsData;
}
- (SRTPosition*)mutablePositionBytes;
@end

@implementation PSDrawingGroup

@dynamic name;
@dynamic children;
@dynamic drawingLines;
@dynamic positionsAsData;
@dynamic parent;
@synthesize isSelected;



- (int)addPosition:(SRTPosition)position withInterpolation:(BOOL)shouldInterpolate
{
	const int FPS_MULTIPLE = 4;
	// We want to cap the rate that we are storing datapoints at.
	// Keeping the flow of data low will make life a lot easier on playback
	// On playback, they will still be interpolated to smooth them out
	// We want to cap it at a multiple of the POSITION_FPS, so that the keyframes
	// in the timeline will not be affected by this step
	position.timeStamp = roundf(position.timeStamp * (FPS_MULTIPLE*POSITION_FPS))
						/(FPS_MULTIPLE*POSITION_FPS);

	// For interpolation, save a copy of what the position was at this time before we change it
	SRTPosition previousPositionAtTime = SRTPositionZero();
	if(shouldInterpolate)
		[self getStateAtTime:position.timeStamp
					position:&previousPositionAtTime
						rate:nil
				 helperIndex:nil];
	
	// Get a handle to a mutable version of our positions list
	int currentPositionCount = self.positionCount;
	SRTPosition* currentPositions = [self mutablePositionBytes];
	

	// Find the index to insert it at
	int newIndex = 0;
	while (newIndex < currentPositionCount &&
		   currentPositions[newIndex].timeStamp < position.timeStamp)
		newIndex++;
	

	BOOL overwriting = newIndex < currentPositionCount && 
						currentPositions[newIndex].timeStamp == position.timeStamp;

	// Make space for the new entry if necessary
	if(!overwriting)
	{
		[_mutablePositionsAsData increaseLengthBy:sizeof(SRTPosition)];
		currentPositions = (SRTPosition*)_mutablePositionsAsData.bytes;

		//Move everything down!
		memmove(currentPositions + newIndex + 1, 
				currentPositions + newIndex ,
				(currentPositionCount - newIndex)*sizeof(SRTPosition));
		
		currentPositionIndex++;
	}
	
	// If this time is already a keyframe, tag the new position as a keyframe too
	if(overwriting)
		position.keyframeType = SRTKeyframeAdd2(position.keyframeType,
												currentPositions[newIndex].keyframeType);
	
	//Write the new one
	currentPositions[newIndex] = position;
	if (! overwriting) currentPositionCount ++;
	
	
	// Interpolate from previous keyframes if it has been requested
	// Look for the keyframes that surround our new position
	// (The first and last position in the list are treated as implicit keyframes)
	// Then modify them by a percent of the delta between the new position and
	// our previous position at this time
	if(shouldInterpolate)
	{
		// Figure out what we are interpolating by comparing with previous value for this time
		SRTPosition delta = SRTPositionGetDelta(previousPositionAtTime, position);
		
		// Fix up the elements before our new position
		if(newIndex > 0)
		{
			// Find the previous index to interpolate from
			// This involves looking for the first keyframe that contains all of the keyframes in position
			int previousKeyframeIndex = newIndex - 1;
			while ( previousKeyframeIndex > 0 &&
				   !SRTKeyframeIsAny(currentPositions[previousKeyframeIndex].keyframeType))
				previousKeyframeIndex --;
			
			SRTPosition previousKeyframe = currentPositions[previousKeyframeIndex];
			
			// Apply the change to the intermediate positions
			for(int i = previousKeyframeIndex + 1; i < newIndex; i++)
			{
				float t = currentPositions[i].timeStamp;
				float pcnt = (t - previousKeyframe.timeStamp)/(position.timeStamp - previousKeyframe.timeStamp);
				currentPositions[i] = SRTPositionApplyDelta(currentPositions[i], delta, pcnt);
			}
		}
		
		// Fix up the elements after our new position
		if(newIndex < currentPositionCount - 1)
		{
			// Find the next index to interpolate from
			int nextKeyframeIndex = newIndex + 1;
			while ( nextKeyframeIndex < currentPositionCount - 1 &&
				   !SRTKeyframeIsAny(currentPositions[nextKeyframeIndex].keyframeType))
				nextKeyframeIndex ++;
			
			SRTPosition nextKeyframe = currentPositions[nextKeyframeIndex];
			
			// Apply the change to the intermediate positions
			for(int i = nextKeyframeIndex - 1; i > newIndex; i--)
			{
				float t = currentPositions[i].timeStamp;
				float pcnt = 1.0 - (t - position.timeStamp)/(nextKeyframe.timeStamp - position.timeStamp);
				currentPositions[i] = SRTPositionApplyDelta(currentPositions[i], delta, pcnt);
			}
		}

	}
	
	return newIndex;
}


- (void)pauseUpdatesOfTranslation:(BOOL)translation rotation:(BOOL)rotation scale:(BOOL)scale
{
	_pausedTranslation = translation;
	_pausedRotation = rotation;
	_pausedScale = scale;
}

- (void)unpauseAll
{
	[self pauseUpdatesOfTranslation:NO rotation:NO scale:NO];
}

- (SRTPosition*)positions
{
	if (_mutablePositionsAsData != nil)
		return (SRTPosition*)_mutablePositionsAsData.bytes;
	else
		return (SRTPosition*)self.positionsAsData.bytes;

}


- (void)doneMutatingPositions
{
	// This will also mark the object as dirty
	if(_mutablePositionsAsData)
		self.positionsAsData = _mutablePositionsAsData;
	
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

- (CGPoint)currentOriginInWorldCoordinates
{
	// TODO: I don't think this will work properly for nested groups!
	return CGPointFromGLKVector2(currentSRTPosition.location);
}


- (SRTPosition)currentCachedPosition
{
	return currentSRTPosition;
}

- (void)setCurrentCachedPosition:(SRTPosition)position
{
	currentSRTPosition = position;
	//TODO, this is so ugly
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
	currentPositionIndex = 0;
	currentModelViewMatrix = GLKMatrix4Identity;
	isSelected = NO;
	_mutablePositionsAsData = nil;
	[self unpauseAll];
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
	currentPositionIndex = 0;
	currentModelViewMatrix = GLKMatrix4Identity;
	isSelected = NO;
	_mutablePositionsAsData = nil;
	[self unpauseAll];
}


/*
 This is called after undo/redo types of events
 Copy our pointsAsData back into our points buffer after the change
 */
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	[super awakeFromSnapshotEvents:flags];
	[self unpauseAll];
	isSelected = NO;
	_mutablePositionsAsData = nil;
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



- (void)centerOnCurrentBoundingBox
{
	// 1. Figure out the point we want to center on (in the parent's coordinates)
	CGPoint newCenter = CGRectGetCenter([self currentBoundingRect]);
	CGAffineTransform offsetForward = CGAffineTransformMakeTranslation(newCenter.x, newCenter.y);
	CGAffineTransform offsetBackward = CGAffineTransformMakeTranslation(-newCenter.x, -newCenter.y);
	
	// 2. Fix up our lines
	[self applyTransformToLines:offsetBackward];
	
	// 3. Fix up our own location
	[self applyTransformToPath:offsetForward];

	// 4. Fix our our children's locations
	for (PSDrawingGroup* g in self.children)
		[g applyTransformToPath:offsetBackward];
}


- (void)applyTransformToLines:(CGAffineTransform)transform
{
	/*	Brute-force adjusting the points of the lines in this group
		Very slow and destructive to the original point information.
		Use sparingly, only to manipulate the basic data and not 
		just to adjust the display of a group.
	*/
	
	for (PSDrawingLine* line in self.drawingLines)
		[line applyTransform:transform];
}


- (void)applyTransformToPath:(CGAffineTransform)transform
{
	SRTPosition* positions = self.mutablePositionBytes;
	SRTPosition transformAsDelta = SRTPositionFromTransform(transform);

	for(int i = 0; i < self.positionCount; i++)
	{
		SRTPosition p = positions[i];
		p.location.x += transformAsDelta.location.x;
		p.location.y += transformAsDelta.location.y;
		p.origin.x += transformAsDelta.origin.x;
		p.origin.y += transformAsDelta.origin.y;
		p.rotation += transformAsDelta.rotation;
		p.scale *= transformAsDelta.scale;
		positions[i] = p;
	}
}


- (CGRect)currentBoundingRect
{
	
	CGPoint min = CGPointMake(1e100, 1e100);
	CGPoint max = CGPointMake(-1e100, -1e100);
	for (PSDrawingLine* line in self.drawingLines)
	{
		CGRect lineRect = [line boundingRect];
		if(!CGRectIsNull(lineRect))
		{			
			min.x = MIN(min.x, CGRectGetMinX(lineRect));
			min.y = MIN(min.y, CGRectGetMinY(lineRect));
			max.x = MAX(max.x, CGRectGetMaxX(lineRect));
			max.y = MAX(max.y, CGRectGetMaxY(lineRect));
		}
	}
	
	for (PSDrawingGroup* g in self.children)
	{
		SRTPosition p = g.currentCachedPosition;
		min.x = MIN(min.x, p.location.x);
		min.y = MIN(min.y, p.location.y);
		max.x = MAX(max.x, p.location.x);
		max.y = MAX(max.y, p.location.y);
	}
	
	return CGRectMake(min.x, min.y, max.x - min.x, max.y - min.y);
}


- (SRTPosition*)mutablePositionBytes
{
	if ( _mutablePositionsAsData == nil )
		_mutablePositionsAsData = [NSMutableData dataWithData:self.positionsAsData];
	return (SRTPosition*)_mutablePositionsAsData.bytes;
}

- (GLKMatrix4)currentModelViewMatrix
{
	return currentModelViewMatrix;
}



/*
	TODO: This really requires some explanation....
	(Trying to get a projection matrix that will keep this group from moving)
*/
- (GLKMatrix4)getInverseMatrixToDocumentRoot
{
	GLKMatrix4 parentInverted = (self.parent == nil) ?
										GLKMatrix4Identity :
										[self.parent getInverseMatrixToDocumentRoot];
	
	bool isInvertable;
	GLKMatrix4 selfInverted = GLKMatrix4Invert(currentModelViewMatrix, &isInvertable);
	if(!isInvertable) NSLog(@"!!!! SHOULD ALWAYS BE INVERTABLE!!!");
	return GLKMatrix4Multiply(selfInverted, parentInverted);
}

- (BOOL)eraseAtPoint:(CGPoint)p
{
	// Bring it into our coordinates
	CGPoint fixedP = [self translatePointFromParentCoordinates:p];
	
	for (PSDrawingLine* l in [self.drawingLines copy])
		if([l eraseAtPoint:fixedP])
			[PSDataModel deleteDrawingLine:l];
	
	for (PSDrawingGroup* g in [self.children copy])
		if([g eraseAtPoint:fixedP])
			[PSDataModel deleteDrawingGroup:g];
	
	
	return (self.drawingLines.count == 0 && self.children.count == 0);
}

- (CGPoint)translatePointFromParentCoordinates:(CGPoint)p
{
	bool isInvertable;
	GLKMatrix4 selfInverted = GLKMatrix4Invert(currentModelViewMatrix, &isInvertable);
	if(!isInvertable) NSLog(@"!!!! SHOULD ALWAYS BE INVERTABLE!!!");
	GLKVector4 v4 = GLKMatrix4MultiplyVector4(selfInverted, GLKVector4FromCGPoint(p));
	return CGPointFromGLKVector4(v4);
}

- (BOOL)hitsPoint:(CGPoint)p
{
	// return true if any line in this group or its children is hit
	// p is assumed to be in this group's parent's coordinate system
	CGPoint fixedP = [self translatePointFromParentCoordinates:p];
	
	for (PSDrawingLine* l in self.drawingLines)
		if ([l hitsPoint:fixedP])
			return YES;
	
	for (PSDrawingGroup* g in self.children)
		if ([g hitsPoint:fixedP])
			return YES;
	
	return NO;
}


- (void)deleteSelectedChildren
{
	for (PSDrawingGroup* g in [self.children copy])
	{
		if (g.isSelected)
			[PSDataModel deleteDrawingGroup:g];
		else
			[g deleteSelectedChildren];
	}
}

- (PSDrawingGroup*)mergeSelectedChildrenIntoNewGroup
{
	// Create a new group to hold the children
	PSDrawingGroup* newGroup = [PSDataModel newDrawingGroupWithParent:self];

	// Collect the groups
	NSMutableArray* selected = [NSMutableArray array];
	[self applyToSelectedSubTrees:^(PSDrawingGroup *g) {
		[selected addObject:g];
	}];

	// Add them to the new group
	for (PSDrawingGroup* g in selected)
		g.parent = newGroup;
		// TODO: we probably should displace the selected groups to keep them from jumping around?

	return newGroup;
}

- (PSDrawingGroup*)topLevelSelectedChild
{
	// This assumes that there is a single subtree with selected nodes
	for (PSDrawingGroup* g in self.children)
		if (g.isSelected)
			return g;

	for (PSDrawingGroup* g in self.children)
	{
		PSDrawingGroup* result = [g topLevelSelectedChild];
		if(result) return result;
	}
	
	return nil;
}


- (void)breakUpGroupAndMergeIntoParent
{
	for (PSDrawingGroup* g in [self.children copy])
		g.parent = self.parent;
	
	[PSDataModel deleteDrawingGroup:self];
}


- (void)transformSelectionByX:(float)dX
						 andY:(float)dY
					 rotation:(float)dRotation
						scale:(float)dScale
				   visibility:(BOOL)makeVisible
					   atTime:(float)time
			   addingKeyframe:(SRTKeyframeType)keyframeType
		   usingInterpolation:(BOOL)interpolate
{
	[self applyToSelectedSubTrees:^(PSDrawingGroup *g) {

		// Start with our current position and apply these deltas
		SRTPosition position = g.currentCachedPosition;
		position.location.x += dX;
		position.location.y += dY;
		position.rotation += dRotation;
		position.scale *= dScale;
		position.timeStamp = time;
		position.keyframeType = keyframeType;
		position.isVisible = makeVisible;
		
		//Store the position at the current time and refresh the cache
		[g addPosition:position withInterpolation:interpolate];
		g.currentCachedPosition = position;
	}];
}

- (void)applyToAllSubTrees:( void ( ^ )( PSDrawingGroup*, BOOL) )functionToApply
{
	[self applyToAllSubTrees:functionToApply parentIsSelected:self.isSelected];
}

- (void)applyToAllSubTrees:(void (^)(PSDrawingGroup *, BOOL))functionToApply parentIsSelected:(BOOL)parentSelected
{
	functionToApply(self, self.isSelected || parentSelected);

	for (PSDrawingGroup* c in self.children)
		[c applyToAllSubTrees:functionToApply parentIsSelected:self.isSelected || parentSelected];
}

- (void)applyToSelectedSubTrees:( void ( ^ )( PSDrawingGroup* g ) )functionToApply
{
	if(self.isSelected)
		functionToApply(self);
	else
		for (PSDrawingGroup* c in self.children)
			[c applyToSelectedSubTrees:functionToApply];
}



- (PSRecordingSession*)startSelectedGroupsRecordingTranslation:(BOOL)isTranslating
													  rotation:(BOOL)isRotating
													   scaling:(BOOL)isScaling
														atTime:(float)time
{
	// Create a recording session
	PSRecordingSession* session = [[PSRecordingSession alloc] initWithTranslation:isTranslating
																		 rotation:isRotating
																			scale:isScaling
																   startingAtTime:time];
	
	// Add each selected group to the session
	[self applyToSelectedSubTrees:^(PSDrawingGroup *g) {

		[session addGroupToSession:g];

	}];

	return session;
}


- (void)setVisibility:(BOOL)visible atTime:(float)time
{
	// STEP 1: add a new keyframe to set the visibility at time
	SRTPosition pos;
	[self getStateAtTime:time position:&pos rate:nil helperIndex:nil];
	
	// If there is already a visibility keyframe at this point, clear it instead of setting a new one
	if (pos.timeStamp != time)
		pos.keyframeType = SRTKeyframeMake(NO, NO, NO, YES);
	else if (SRTKeyframeIsVisibility(pos.keyframeType))
		pos.keyframeType = SRTKeyframeRemove(pos.keyframeType, NO, NO, NO, YES);
	else
		pos.keyframeType = SRTKeyframeAdd(pos.keyframeType, NO, NO, NO, YES);

	pos.isVisible = visible;
	pos.timeStamp = time;
	
	// Add it to the list
	int i = [self addPosition:pos withInterpolation:NO];
	
	// STEP 2: Move forward until the next visibility keyframe and change the visibility
	SRTPosition* positions = [self mutablePositionBytes];
	i += 1;
	while (i < self.positionCount && !SRTKeyframeIsVisibility(positions[i].keyframeType))
	{
		positions[i].isVisible = visible;
		i++;
	}
	
	// STEP 3:If we ended by hitting the next visibility keyframe, remove it since it is redundant now
	if(i < self.positionCount)
		positions[i].keyframeType = SRTKeyframeRemove(positions[i].keyframeType, NO, NO, NO, YES);
	
	
	currentSRTPosition = pos;
}


- (void)printSelected:(int)depth
{
	NSLog(@"%d:\t------------ %@", depth, (self.isSelected ? @"SELECTED" : @"NO!"));
	for (PSDrawingGroup* g in self.children)
		[g printSelected:depth+1];
	
}

- (void)setPosition:(SRTPosition)p atIndex:(int)i
{
	self.mutablePositionBytes[i] = p;
}

@end
