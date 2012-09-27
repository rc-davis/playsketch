/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


#import "PSRecordingSession.h"
#import "PSDrawingGroup.h"

@interface PSRecordingSession ()
@property(nonatomic,retain)NSMutableArray* groups;
@property(nonatomic,retain)NSMutableArray* groupIndexes;
@property(nonatomic) BOOL overwriteTranslation;
@property(nonatomic) BOOL overwriteRotation;
@property(nonatomic) BOOL overwriteScale;
@property(nonatomic) float currentTime;

- (SRTPosition)maskedCopyFrom:(SRTPosition)from to:(SRTPosition)to;
@end

@implementation PSRecordingSession

- (id)initWithTranslation:(BOOL)overwriteTranslation
				 rotation:(BOOL)overwriteRotation
					scale:(BOOL)overwriteScale
		   startingAtTime:(float)startTime
{
	if (self = [super init]) {

		self.groups = [NSMutableArray array];
		self.groupIndexes = [NSMutableArray array];
		self.overwriteTranslation = overwriteTranslation;
		self.overwriteRotation = overwriteRotation;
		self.overwriteScale = overwriteScale;
		self.currentTime = startTime;
	}
	return self;
}


- (void)addGroupToSession:(PSDrawingGroup *)g
{
	// Pause the group so it won't keep moving when we hit play
	[g pauseUpdatesOfTranslation:self.overwriteTranslation
						rotation:self.overwriteRotation
						   scale:self.overwriteScale];

	
	// Add a keyframe for the start position based on our current position
	SRTPosition currentPos = g.currentCachedPosition;
	currentPos.timeStamp = self.currentTime;
	currentPos.isVisible = YES;
	currentPos.keyframeType = SRTKeyframeMake(self.overwriteScale,
											  self.overwriteRotation,
											  self.overwriteTranslation,
											  NO);
	int currentIndex = [g addPosition:currentPos withInterpolation:NO];


	//Remember the index of this start position for future math
	[self.groupIndexes addObject:[NSNumber numberWithInt:currentIndex]];
	[self.groups addObject:g];

}


- (void)transformAllGroupsByX:(float)dX
						 andY:(float)dY
					 rotation:(float)dRotation
						scale:(float)dScale
					   atTime:(float)time
{
	for (int i = 0; i < self.groups.count; i++)
	{
		PSDrawingGroup* g = self.groups[i];
		int lastIndex = [self.groupIndexes[i] intValue];
		SRTPosition* positions = g.positions;

		// Remember the new keyframe
		SRTPosition lastFrame = positions[lastIndex];
		SRTPosition newFrame = g.currentCachedPosition;
		
		if (self.overwriteTranslation)
		{
			newFrame.location.x = lastFrame.location.x + dX;
			newFrame.location.y = lastFrame.location.y + dY;
		}

		if (self.overwriteRotation)
			newFrame.rotation = lastFrame.rotation + dRotation;
		
		if (self.overwriteScale)
			newFrame.scale = lastFrame.scale * dScale;
		
		newFrame.timeStamp = time;
		newFrame.isVisible = YES;
		newFrame.keyframeType = SRTKeyframeTypeNone();

		int nextIndex = [g addPosition:newFrame withInterpolation:NO];
		
		newFrame = g.positions[nextIndex];

		// TODO: I think there's some bad bugs in how we are setting keyframes in here
		// We probably need to do something smarter for which keyframes we are setting
		// I think we're being too aggressive about erasing pre-existing keyframes
		newFrame.keyframeType = SRTKeyframeTypeNone();
		[g setPosition:newFrame atIndex:nextIndex];
		
		
		g.currentCachedPosition = newFrame;
		
		// Clean up between the two to make sure we don't get jumping around
		for(int j = lastIndex + 1; j < nextIndex; j++)
		{
			SRTPosition newP = [self maskedCopyFrom:positions[lastIndex] to:positions[j]];
			newP.keyframeType = SRTKeyframeTypeNone();
			newP.isVisible = YES;
			[g setPosition:newP atIndex:j];
		}

		self.groupIndexes[i] = [NSNumber numberWithInt:nextIndex];
		
	}
	
	self.currentTime = time;
}


- (void)finishAtTime:(float)time
{
	for (int i = 0; i < self.groups.count; i++)
	{
		PSDrawingGroup* g = self.groups[i];
		SRTPosition* positions = g.positions;

		// 1. Retrieve the last position we inserted
		int lastIndex = [self.groupIndexes[i] intValue];
		SRTPosition lastPosition = positions[lastIndex];
		
		// 2. Insert it again at "time", because "time" will be snapped to a keyframe time boundary by now
		lastPosition.timeStamp = time;
		lastPosition.keyframeType = SRTKeyframeMake(self.overwriteScale,
													self.overwriteRotation,
													self.overwriteTranslation, NO);

		int newLastIndex = [g addPosition:lastPosition withInterpolation:NO];
		g.currentCachedPosition = lastPosition;

		// 3. Remove any keyframes between lastIndex and newLastIndex
		for(int j = lastIndex + 1; j < newLastIndex; j++)
		{
			SRTPosition newP = [self maskedCopyFrom:positions[lastIndex] to:positions[j]];
			newP.keyframeType = SRTKeyframeTypeNone();
			[g setPosition:newP atIndex:j];
		}
		
		// 3. Clean up from here to the end of the data
		for(int j = newLastIndex + 1; j < g.positionCount; j++)
		{
			SRTPosition newP = [self maskedCopyFrom:positions[newLastIndex] to:positions[j]];
			newP.keyframeType = SRTKeyframeTypeNone();
			[g setPosition:newP atIndex:j];
		}
		
		[g unpauseAll];
	}
}


- (SRTPosition)maskedCopyFrom:(SRTPosition)from to:(SRTPosition)to
{
	if(self.overwriteTranslation)
		to.location = from.location;
	if (self.overwriteRotation)
		to.rotation = from.rotation;
	if (self.overwriteScale)
		to.scale = from.scale;
	to.isVisible = YES;
	to.keyframeType = SRTKeyframeRemove(to.keyframeType, self.overwriteScale, self.overwriteRotation, self.overwriteTranslation, YES);
	
	return  to;
}

@end
