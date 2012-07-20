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
#import "PSDrawingGroup.h"
#import "PSDrawingLine.h"


@implementation PSDrawingGroup

@dynamic name;
@dynamic rootGroup;
@dynamic children;
@dynamic drawingLines;
@dynamic parent;


- (void)awakeFromInsert
{
	// TODO TEMP: Setting these explicitly
	// Make sure we are pulling these out of a time-indexed list
	currentSRTPosition = SRTPositionMake( 0, 0, 1, 0, 0, 0);
	currentSRTRate = SRTRateMake( 0, 0, 0, 0 );
}

- (void)awakeFromFetch
{
	// TODO TEMP: Setting these explicitly
	// Make sure we are pulling these out of a time-indexed list
	currentSRTPosition = SRTPositionMake( 0, 0, 1, 0, 0, 0);
	currentSRTRate = SRTRateMake( 0, 0, 0, 0 );
}

/*
	Find the max and min points across our children
	This is not cached (maybe it should be if this is needed often?)
*/
- (CGRect)calculateFrame
{
	return [PSDrawingLine calculateFrameForLines:self.drawingLines];
}


// TODO TEMPORARY DELETE THIS WHEN WE HAVE A PATH
-(void)setCurrentSRTRate:(SRTRate)r
{
	currentSRTRate = r;
}

-(void)setCurrentSRTPosition:(SRTPosition)p
{
	currentSRTPosition = p;
}

@end
