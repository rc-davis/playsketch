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

@implementation PSGroupOverlayButtons


- (id)init
{
	CGRect defaultFrame = CGRectMake(0, 0, 100, 100);
	self = [super initWithFrame:defaultFrame];
    if (self)
	{
		self.backgroundColor = [UIColor redColor];
    }
    return self;	
}


- (void)configureForGroup:(PSDrawingGroup*)group
{
	//Decide what buttons to show
	
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
