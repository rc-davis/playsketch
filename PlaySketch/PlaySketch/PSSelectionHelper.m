/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


#import "PSSelectionHelper.h"


@interface PSSelectionHelper ()
@property(nonatomic)CGPoint firstPoint;
@property(nonatomic)BOOL haveFirstPoint;
@property(nonatomic)PSDrawingGroup* rootGroup;
@property(readwrite)int selectedGroupCount;
- (void) prepareForSelection:(PSDrawingGroup*)g;
- (BOOL)selectAtTap:(CGPoint)tap inGroup:(PSDrawingGroup*)group;
@end


@implementation PSSelectionHelper


+(PSSelectionHelper*)selectionWithLine:(PSDrawingLine*)line inRootGroup:(PSDrawingGroup*)rootGroup
{
	PSSelectionHelper* h = [[PSSelectionHelper alloc] init];
	h.rootGroup = rootGroup;
	h.selectionLoupeLine = line;
	h.haveFirstPoint = NO;
	
	// Reset the selection information for all of these objects
	// Each group maintains a BOOL of whether it is selected
	// Each line contains a list with an int for each point for selection crossing count
	h.selectedGroupCount = 0;
	[h prepareForSelection:rootGroup];
	
	return h;
}

+(PSSelectionHelper*)selectionForTap:(CGPoint)tapPoint inRootGroup:(PSDrawingGroup*)rootGroup
{
	PSSelectionHelper* h = [[PSSelectionHelper alloc] init];
	h.rootGroup = rootGroup;
	h.selectionLoupeLine = nil;
	h.haveFirstPoint = NO;
	
	// Reset the selection information for all of these objects
	// Each group maintains a BOOL of whether it is selected
	// Each line contains a list with an int for each point for selection crossing count
	h.selectedGroupCount = 0;
	[h prepareForSelection:rootGroup];

	BOOL hits = [h selectAtTap:tapPoint inGroup:rootGroup];
	if(hits) h.selectedGroupCount = 1;

	//The root group should NEVER be selected (since you can't transform it!)
	rootGroup.isSelected = NO;
	
	return h;
}

-(void)addLineFrom:(CGPoint)from to:(CGPoint)to
{
	// Save this as our first point if we don't have one already
	if (! _haveFirstPoint )
	{
		self.firstPoint = from;
		self.haveFirstPoint = YES;
	}
	
	// Perturb our number by a sub-pixel to avoid infinities
	BOOL degenerateForward = ( to.x == from.x );
	BOOL degenerateReverse = ( to.x == _firstPoint.x );

	// Calculate m,b for y = mx+b between the two points
	CGFloat mForward = (!degenerateForward) ? ( to.y - from.y ) / ( to.x - from.x ) : 1e99;
	CGFloat bForward = from.y - mForward * from.x;
	CGFloat minXForward = MIN(from.x, to.x);
	CGFloat maxXForward = MAX(from.x, to.x);

	// Calculate m,b for the line back to the first point (closing the loop)
	CGFloat mReverse = (!degenerateReverse) ? ( to.y - _firstPoint.y ) / ( to.x - _firstPoint.x ) : 1e99;
	CGFloat bReverse = _firstPoint.y - mReverse * _firstPoint.x;
	CGFloat minXReverse = MIN(_firstPoint.x, to.x);
	CGFloat maxXReverse = MAX(_firstPoint.x, to.x);
		
	
	// Recurse on the root group looking for crossings
	[self updateSelectionOnGroup:self.rootGroup
					 forwardMinX:minXForward
					 forwardMaxX:maxXForward
						forwardB:bForward
						forwardM:mForward
					 reverseMinX:minXReverse
					 reverseMaxX:maxXReverse
						reverseB:bReverse
						reverseM:mReverse];
	
}

- (void) updateSelectionOnGroup:(PSDrawingGroup*)group
					forwardMinX:(CGFloat)minXForward
					forwardMaxX:(CGFloat)maxXForward
					   forwardB:(CGFloat)bForward
					   forwardM:(CGFloat)mForward
					reverseMinX:(CGFloat)minXReverse
					reverseMaxX:(CGFloat)maxXReverse
					   reverseB:(CGFloat)bReverse
					   reverseM:(CGFloat)mReverse
{
	// Step 1: Find out if any of the lines that belong to THIS group are hit
	BOOL anyLineSelected = NO;
	for (PSDrawingLine* line in group.drawingLines)
	{
		BOOL lineIsHit = NO;
		for(int i = 0; i < [line pointCount]; i++)
		{
			CGPoint p = [line points][i];
			
			// Test if we hit the new line
			BOOL hitsForward =	p.x >= minXForward &&
			p.x < maxXForward &&
			(mForward * p.x + bForward) > p.y;
			
			// Test if we hit the reverse line
			BOOL hitsReverse =	p.x >= minXReverse &&
			p.x < maxXReverse &&
			(mReverse * p.x + bReverse) > p.y;
			
			
			if ( hitsForward )
				line.selectionHitCounts[i] += 1;
			
			//if (hitsForward || hitsReverse)
			//	NSLog(@"here");
			
			int inferredCount = hitsReverse ? 1 : 0;
			
			// It hits if our sum of crossings is odd
			lineIsHit = lineIsHit ||
			(line.selectionHitCounts[i] + inferredCount) %2 == 1;
			
			
		}
		
		anyLineSelected = anyLineSelected || lineIsHit;
	}

	// Step 2: Recurse and select if ALL of the child groups are hit
	BOOL allChildrenSelected = YES;
	for (PSDrawingGroup* g in group.children)
	{
		// TODO: We'll need to push the group's current matrix before recursing
		// to accomodate when the animation has moved the lines to a different position.
		
		[self updateSelectionOnGroup:g
						 forwardMinX:minXForward
						 forwardMaxX:maxXForward
							forwardB:bForward
							forwardM:mForward
						 reverseMinX:minXReverse
						 reverseMaxX:maxXReverse
							reverseB:bReverse
							reverseM:mReverse];

		allChildrenSelected = allChildrenSelected && g.isSelected;
	}

	BOOL shouldBeSelected = anyLineSelected || (allChildrenSelected && group.children.count > 0);
	if (!group.isSelected && shouldBeSelected) self.selectedGroupCount++;
	if (group.isSelected && !shouldBeSelected) self.selectedGroupCount--;
	group.isSelected = shouldBeSelected;
}

/* 
 pointsDict contains keys "from" and "to", which are CGPoints encoded with NSValue
 It is helpful to wrap them this way so we can call this on a background thread.
 (Data can only be passed from the foreground to the background thread on the heap,
 so it needs to be an object)
 */
-(void)addLineFromDict:(NSDictionary*)pointsDict
{
	CGPoint from = [[pointsDict objectForKey:@"from"] CGPointValue];
	CGPoint to = [[pointsDict objectForKey:@"to"] CGPointValue];
	[self addLineFrom:from to:to];
}


- (void) prepareForSelection:(PSDrawingGroup*)g
{
	
	/*
	 reset all of the selection metadata we're tracking in the objects
	*/
	g.isSelected = NO;
	for (PSDrawingLine* l in g.drawingLines)
		[l prepareForSelection];
	for (PSDrawingGroup* c in g.children)
		[self prepareForSelection:c];
}

/* 
	If any line in this group or its child groups hits the point, 
	mark this group as selected and return YES.
	The isSelected flag is not guaranteed to be selected on any children of the top-most selected group.
	This selects a single group as a result
*/
-(BOOL)selectAtTap:(CGPoint)tap inGroup:(PSDrawingGroup*)group
{
	for (PSDrawingLine* l in group.drawingLines)
	{
		if( [l hitsPoint:tap])
		{
			group.isSelected = YES;
			return YES;
		}
	}
	
	for (PSDrawingGroup* g in group.children)
	{
		if([self selectAtTap:tap inGroup:g])
		{
			group.isSelected = YES;
			return YES;
		}
	}
	return NO;
}

-(void)setSelectedGroupCount:(int)selectedGroupCount
{
	NSLog(@"setting: %d", selectedGroupCount);
	_selectedGroupCount = selectedGroupCount;
}

@end
