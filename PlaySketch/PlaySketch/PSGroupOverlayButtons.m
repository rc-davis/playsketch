/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSGroupOverlayButtons.h"
#import "PSDrawingGroup.h"

@implementation PSGroupOverlayButtons
@synthesize createGroupButton;

- (void)configureForGroup:(PSDrawingGroup*)group
{
	// Decide what buttons to show
	self.createGroupButton.hidden = [group.explicitCharacter boolValue];
	
}

-(void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	
}
- (void)setLocation:(CGPoint)p
{
	NSLog(@"setting loc");
	CGRect newFrame = self.frame;
	newFrame.origin = p;
	self.frame = newFrame;
}

- (void)show:(BOOL)animated
{
	if(animated) [UIView beginAnimations:@"GroupOverlayAppearance" context:nil];
	self.alpha = 1.0;
	if(animated) [UIView commitAnimations];
}

- (void)hide:(BOOL)animated;
{
	if(animated) [UIView beginAnimations:@"GroupOverlayAppearance" context:nil];
	self.alpha = 0.0;
	if(animated) [UIView commitAnimations];

}

@end
