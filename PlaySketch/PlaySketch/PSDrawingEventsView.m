/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


#import "PSDrawingEventsView.h"
#import "PSAppDelegate.h"
#import "PSDataModel.h"

@implementation PSDrawingEventsView
@synthesize currentDrawingGroup = _currentDrawingGroup;
@synthesize currentLine = _currentLine;


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.currentLine = [PSDataModel newLineInGroup:self.currentDrawingGroup];
	NSLog(@"!!!! %@", self.currentDrawingGroup);
}		


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch* touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	p.y = self.bounds.size.height - p.y;
	[self.currentLine addLineFrom:CGPointZero to:p];

}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[PSDataModel save];
	self.currentLine = nil;	
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[PSDataModel deleteDrawingLine:self.currentLine];
	self.currentLine = nil;
}

@end
