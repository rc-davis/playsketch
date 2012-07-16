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
@synthesize drawingDelegate = _drawingDelegate;
@synthesize currentLine = _currentLine;



-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Fetch a line from our delegate to put our touch points into
	if(self.drawingDelegate)
		self.currentLine = [self.drawingDelegate newLineToDrawTo:self];
}		


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(self.currentLine)
	{
		UITouch* touch = [touches anyObject];
		CGPoint p = [touch locationInView:self];
		p.y = self.bounds.size.height - p.y;
		CGPoint previous = [touch previousLocationInView:self];
		previous.y = self.bounds.size.height - previous.y;

		[self.currentLine addLineFrom:previous to:p];
	}
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{

	if(self.currentLine)
	{
		if (self.drawingDelegate)
			[self.drawingDelegate finishedDrawingLine:self.currentLine inDrawingView:self];
		self.currentLine = nil;	
	}

}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	
	if(self.currentLine)
	{
		if (self.drawingDelegate)
			[self.drawingDelegate cancelledDrawingLine:self.currentLine inDrawingView:self];
		self.currentLine = nil;	
	}

}

@end
