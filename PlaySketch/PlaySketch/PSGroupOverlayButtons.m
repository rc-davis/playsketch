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
@synthesize recordingButton = _recordingButton;
@synthesize showDetailsButton = _showDetailsButton;
@synthesize recordPulsing = _recordPulsing;

- (void)configureForGroup:(PSDrawingGroup*)group
{
	// Decide what buttons to show
	BOOL isExplicit = [group.explicitCharacter boolValue];
	self.recordingButton.hidden = !isExplicit;
	self.showDetailsButton.hidden = !isExplicit;
	self.deleteGroupButton.hidden = !isExplicit;
	
	//Lay them out dynamically
	NSArray* allButtons = [NSArray arrayWithObjects:self.recordingButton,
													self.showDetailsButton,
													self.deleteGroupButton,
													nil];
	CGFloat yOffset = 0;
	for (UIButton* b in allButtons)
	{
		if (b.hidden) continue;
		CGRect f = b.frame;
		f.origin.y = yOffset;
		b.frame = f;
		yOffset += f.size.height;
	}
	
}

- (void)setLocation:(CGPoint)p
{
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


- (void)startRecordingMode
{
	self.recordingButton.selected = YES;
	
}

- (void)stopRecordingMode
{
	self.recordingButton.selected = NO;
}

- (void)setRecordPulsing:(BOOL)recordPulsing
{
	UIColor* color1 = [UIColor colorWithRed:0.504 green:0.010 blue:0.021 alpha:1.000];
	UIColor* color2 = [UIColor colorWithRed:1.000 green:0.019 blue:0.041 alpha:1.000];
	
	if (recordPulsing && !_recordPulsing)
	{
		// Start pulsing
		self.recordingButton.backgroundColor = color1;
		[UIView animateWithDuration:1.0
							  delay:0.0
							options:UIViewAnimationOptionRepeat |
									UIViewAnimationOptionAutoreverse |
									UIViewAnimationOptionCurveEaseInOut
						 animations: ^{ self.recordingButton.backgroundColor = color2; }
						 completion:nil];

	}
	else if (!recordPulsing && _recordPulsing)
	{
		// Stop pulsing and go back to the original color
		[UIView animateWithDuration:0.3
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations: ^{ self.recordingButton.backgroundColor = color1; }
						 completion:nil];
	}

	_recordPulsing = recordPulsing;
}

@end
