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
@property(nonatomic,retain) NSSet* allLines;
@property(nonatomic)CGPoint firstPoint;
@property(nonatomic)int* lineHitCounts; // Ugly but fast way to maintain count of line crossings
@property(nonatomic)BOOL haveFirstPoint;
@end


@implementation PSSelectionHelper
@synthesize selectionLoupeLine = _selectionLoupeLine;
@synthesize allLines = _allLines;
@synthesize selectedLines = _selectedLines;
@synthesize firstPoint = _firstPoint;
@synthesize lineHitCounts = _lineHitCounts;
@synthesize haveFirstPoint = _haveFirstPoint;

-(id)initWithGroup:(PSDrawingGroup*)rootGroup andLine:(PSDrawingLine*)line
{
	if(self = [super init])
	{
		self.selectionLoupeLine = line;
		
		self.selectedLines = [NSMutableSet set];
		self.haveFirstPoint = NO;
	
		self.allLines = rootGroup.drawingLines;
		
		//Allocate space for lineHitCounts (ugly)
		int totalLineCount = 0;
		for (PSDrawingLine* line in self.allLines)
			totalLineCount += line.pointCount;
		self.lineHitCounts = (int*)malloc( sizeof(int) * totalLineCount );
		memset(self.lineHitCounts, 0, sizeof(int) * totalLineCount);
		

		/* 
			NOTE: We are just looking at the drawings directly associated with 
			this child. By design, we don't want hits from nested groups.
			If this design change, here this is where we will want to:
			a) recurse and build a single list of lines
			b)  bring all of the lines into the same coordinate space and cache it for addLine:
		*/

	}
	
	return self;
}

-(void)dealloc
{
	free(self.lineHitCounts);

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
	if ( to.x == from.x ) to.x += 0.25;
	if ( to.x == _firstPoint.x ) to.x += 0.25;

	// Calculate m,b for y = mx+b between the two points
	CGFloat mForward = ( to.y - from.y ) / ( to.x - from.x );
	CGFloat bForward = from.y - mForward * from.x;
	CGFloat minXForward = MIN(from.x, to.x);
	CGFloat maxXForward = MAX(from.x, to.x);

	// Calculate m,b for the line back to the first point (closing the loop)
	CGFloat mReverse = ( to.y - _firstPoint.y ) / ( to.x - _firstPoint.x );
	CGFloat bReverse = _firstPoint.y - mReverse * _firstPoint.x;
	CGFloat minXReverse = MIN(_firstPoint.x, to.x);
	CGFloat maxXReverse = MAX(_firstPoint.x, to.x);
	
	// Make a copy of the current set of selected lines for us to add and remove from
	// Doing it this way is slower than directly changing self.selectedLines, but 
	// it can be done in the background since it doesn't disturb the current set 
	// which may be getting drawn to the screen
	NSMutableSet* newSelectedLines = [self.selectedLines mutableCopy];
	
	// Iterate through the lines and update crossing count for each point in each line
	int cumulativeLineCount = 0; // for indexing into lineHitCount
	for (PSDrawingLine* line in self.allLines)
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
				_lineHitCounts[cumulativeLineCount]++;

			int inferredCount = hitsReverse ? 1 : 0;

			
			// It hits if our sum of crossings is odd
			lineIsHit = lineIsHit || 
						(_lineHitCounts[cumulativeLineCount] + inferredCount) %2 == 1;

			cumulativeLineCount ++;
		}								

		//Add or remove it from our new set of lines
		if ( lineIsHit )
		{
			[newSelectedLines addObject:line];
		}
		else if ( [newSelectedLines containsObject:line] )
		{
			[newSelectedLines removeObject:line];
		}
	}	

	self.selectedLines = newSelectedLines;

}



/* 
 pointsDict contains keys "from" and "to", which are CGPoints encoded with NSValue
 It is helpful to wrap them this way so we can call this on a background thread
 */
-(void)addLineFromDict:(NSDictionary*)pointsDict
{
	CGPoint from = [[pointsDict objectForKey:@"from"] CGPointValue];
	CGPoint to = [[pointsDict objectForKey:@"to"] CGPointValue];
	[self addLineFrom:from to:to];
}

@end
