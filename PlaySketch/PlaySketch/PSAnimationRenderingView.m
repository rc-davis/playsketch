/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


#import "PSAnimationRenderingView.h"
#import "PSAppDelegate.h"

@implementation PSAnimationRenderingView
@synthesize currentGroup = _currentGroup;
@synthesize currentLine = _currentLine;

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	PSAppDelegate* appDelegate = (PSAppDelegate*)[[UIApplication sharedApplication] delegate];	
	NSManagedObjectContext *context = [appDelegate managedObjectContext];

	self.currentLine = (PSDrawingLine*)[NSEntityDescription 
										insertNewObjectForEntityForName:@"PSDrawingLine" inManagedObjectContext:context];
	self.currentLine.group = self.currentGroup;
	
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
	PSAppDelegate* appDelegate = (PSAppDelegate*)[[UIApplication sharedApplication] delegate];	
	NSManagedObjectContext *context = [appDelegate managedObjectContext];

	[context save:nil];
	
	self.currentLine = nil;
	
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	
	
}

@end
