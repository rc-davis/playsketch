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


CGPoint __helperFirstPoint;
BOOL __helperHaveFirstPoint;
PSDrawingGroup* __helperRootGroup;
int __helperSelectedGroupCount;

@implementation PSSelectionHelper

+ (void)setRootGroup:(PSDrawingGroup*)group
{
	__helperRootGroup = group;
}

+ (void)resetSelection
{
	[PSHelpers assert:(__helperRootGroup != nil) withMessage:@"Need a root group for the selection helper"];

	__helperSelectedGroupCount = 0;
	__helperHaveFirstPoint = NO;
	
	// Reset all of our per-object metadata
	// Each group maintains a BOOL of whether it is selected
	// Each line contains a list with an int for each point for selection crossing count
	[__helperRootGroup applyToAllSubTrees:^(PSDrawingGroup *g, BOOL subtreeSelected) {
		g.isSelected = NO;
		for (PSDrawingLine* l in g.drawingLines)
		{
			if(l.selectionHitCounts)
				free(l.selectionHitCounts);
			l.selectionHitCounts = (int*)calloc(l.pointCount, sizeof(int));
		}
	}];
}

+ (BOOL)findSelectionForTap:(CGPoint)tapPoint
{
	[PSSelectionHelper resetSelection];
	
	/*
	 If any of our childGroups hits the point it as selected and return YES.
	 Only top-level children will be selected
	 */
	
	for (PSDrawingGroup* g in [__helperRootGroup.children reverseObjectEnumerator])
	{
		if([g hitsPoint:tapPoint])
		{
			g.isSelected = YES;
			__helperSelectedGroupCount = 1;
			return YES;
		 }
	}
	return NO;
}


+ (void)addSelectionLineFrom:(CGPoint)from to:(CGPoint)to
{
	// Save this as our first point if we don't have one already
	if (! __helperHaveFirstPoint )
	{
		__helperFirstPoint = from;
		__helperHaveFirstPoint = YES;
	}
	
	// Perturb our number by a sub-pixel to avoid infinities
	BOOL degenerateForward = ( to.x == from.x );
	BOOL degenerateReverse = ( to.x == __helperFirstPoint.x );

	// Calculate m,b for y = mx+b between the two points
	CGFloat mForward = (!degenerateForward) ? ( to.y - from.y ) / ( to.x - from.x ) : 1e99;
	CGFloat bForward = from.y - mForward * from.x;
	CGFloat minXForward = MIN(from.x, to.x);
	CGFloat maxXForward = MAX(from.x, to.x);

	// Calculate m,b for the line back to the first point (closing the loop)
	CGFloat mReverse = (!degenerateReverse) ?	( to.y - __helperFirstPoint.y ) /
												( to.x - __helperFirstPoint.x ) : 1e99;
	CGFloat bReverse = __helperFirstPoint.y - mReverse * __helperFirstPoint.x;
	CGFloat minXReverse = MIN(__helperFirstPoint.x, to.x);
	CGFloat maxXReverse = MAX(__helperFirstPoint.x, to.x);
		
	
	// Recurse on the root group looking for crossings
	[PSSelectionHelper updateSelectionOnGroup:__helperRootGroup
								  forwardMinX:minXForward
								  forwardMaxX:maxXForward
									 forwardB:bForward
									 forwardM:mForward
								  reverseMinX:minXReverse
								  reverseMaxX:maxXReverse
									 reverseB:bReverse
									 reverseM:mReverse
								   withMatrix:GLKMatrix4Identity];
	
}


+ (void) updateSelectionOnGroup:(PSDrawingGroup*)group
					forwardMinX:(CGFloat)minXForward
					forwardMaxX:(CGFloat)maxXForward
					   forwardB:(CGFloat)bForward
					   forwardM:(CGFloat)mForward
					reverseMinX:(CGFloat)minXReverse
					reverseMaxX:(CGFloat)maxXReverse
					   reverseB:(CGFloat)bReverse
					   reverseM:(CGFloat)mReverse
					 withMatrix:(GLKMatrix4)currentModelViewMatrix
{
	// Step 1: Find out if any of the lines that belong to THIS group are hit
	BOOL anyLineSelected = NO;
	for (PSDrawingLine* line in group.drawingLines)
	{
		BOOL lineIsHit = NO;
		for(int i = 0; i < [line pointCount]; i++)
		{
			CGPoint p = [line points][i];
			
			//translate point into global coordinates so we don't have to update all of our math
			GLKVector4 fixedPoint = GLKMatrix4MultiplyVector4(currentModelViewMatrix, GLKVector4FromCGPoint(p));
			p = CGPointFromGLKVector4(fixedPoint);
			
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
		GLKMatrix4 childMatrix = GLKMatrix4Multiply(currentModelViewMatrix, g.currentModelViewMatrix);
		
		[self updateSelectionOnGroup:g
						 forwardMinX:minXForward
						 forwardMaxX:maxXForward
							forwardB:bForward
							forwardM:mForward
						 reverseMinX:minXReverse
						 reverseMaxX:maxXReverse
							reverseB:bReverse
							reverseM:mReverse
						  withMatrix:childMatrix];

		allChildrenSelected = allChildrenSelected && g.isSelected;
	}

	BOOL shouldBeSelected = anyLineSelected || (allChildrenSelected && group.children.count > 0);
	group.isSelected = shouldBeSelected;
}

/* 
 pointsDict contains keys "from" and "to", which are CGPoints encoded with NSValue
 It is helpful to wrap them this way so we can call this on a background thread.
 (Data can only be passed from the foreground to the background thread on the heap,
 so it needs to be an object)
 */
+ (void)addSelectionLineFromDict:(NSDictionary*)pointsDict
{
	CGPoint from = [[pointsDict objectForKey:@"from"] CGPointValue];
	CGPoint to = [[pointsDict objectForKey:@"to"] CGPointValue];
	[PSSelectionHelper addSelectionLineFrom:from to:to];
}


+ (void)finishLassoSelection
{
	__helperSelectedGroupCount = [PSSelectionHelper countSelectedGroups:__helperRootGroup];
	__helperRootGroup.isSelected = NO; // Make sure we are never selecting the root!
}

+ (BOOL)isSingleLeafOnlySelected
{
	if(__helperSelectedGroupCount== 1)
	{
		PSDrawingGroup* selectedGroup = [__helperRootGroup topLevelSelectedChild];
		if(selectedGroup.children.count == 0 && selectedGroup.drawingLines.count > 0)
			return YES;
	}
	return NO;
}

+ (int)countSelectedGroups:(PSDrawingGroup*)root
{
	int count = 0;
	for (PSDrawingGroup* g in root.children)
		if(g.isSelected)
			count++;
		else
			count += [self countSelectedGroups:g];
	return count;
}

+ (int)selectedGroupCount
{
	return __helperSelectedGroupCount;
}

+ (void)manuallySetSelectedGroup:(PSDrawingGroup*)g
{
	[PSSelectionHelper resetSelection];
	g.isSelected = YES;
	__helperSelectedGroupCount = 1;
	
}

+ (PSDrawingGroup*)leafGroup
{
	if(__helperSelectedGroupCount== 1)
		return [__helperRootGroup topLevelSelectedChild];
	else
		return nil;
}

@end
