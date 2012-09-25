//
//  PSRecordingSession.m
//  PlaySketch
//
//  Created by Ryder Ziola on 2012-09-25.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

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
	currentPos.keyframeType = SRTKeyframeMake(self.overwriteScale,
											  self.overwriteRotation,
											  self.overwriteTranslation);
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
		newFrame.keyframeType = SRTKeyframeMake(self.overwriteScale,
												 self.overwriteRotation,
												 self.overwriteTranslation);
		int nextIndex = [g addPosition:newFrame withInterpolation:NO];
		g.currentCachedPosition = newFrame;
		
		// Clean up between the two to make sure we don't get jumping around
		for(int j = lastIndex + 1; j < nextIndex; j++)
		{
			SRTPosition newP = [self maskedCopyFrom:positions[lastIndex] to:positions[j]];
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
		int lastIndex = [self.groupIndexes[i] intValue];

		[g unpauseAll];
	
		SRTPosition* positions = g.positions;
		
		// Clean up from here to the end of the data
		for(int j = lastIndex + 1; j < g.positionCount; j++)
		{
			SRTPosition newP = [self maskedCopyFrom:positions[lastIndex] to:positions[j]];
			[g setPosition:newP atIndex:j];
		}
		
		// Add our ending keyframe
		// TODO (need to base it on final location?
		
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
	return  to;
}

@end
