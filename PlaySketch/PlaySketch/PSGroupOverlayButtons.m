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

- (void)configureForSelection:(PSSelectionHelper*)helper
{
	BOOL isSingleGroup = helper.selectedGroupCount > 2;
	//TODO: we don't want to call it a single group when it has only one line
	
	// Decide what buttons to show
	self.recordingButton.hidden = NO;
	self.createGroupButton.hidden = isSingleGroup;
	self.disbandGroupButton.hidden = !isSingleGroup;
	self.deleteGroupButton.hidden = NO;
	
	//Lay them out dynamically
	NSArray* allButtons = [NSArray arrayWithObjects:self.recordingButton,
													self.createGroupButton,
													self.disbandGroupButton,
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
