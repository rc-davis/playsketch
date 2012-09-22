/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSPenColorViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation PSPenColorViewController

- (IBAction)setColor:(id)sender
{
	for (UIButton* b in self.colorButtons)
		b.layer.shadowRadius = 0.0;


	UIButton* b = (UIButton*)sender;
	b.layer.shadowRadius = 10.0;
	b.layer.shadowColor = [UIColor yellowColor].CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
	
	if(self.delegate)
		[self.delegate penColorChanged:b.backgroundColor];
}

- (IBAction)setWeight:(id)sender
{
	for (UIButton* b in self.weightButtons)
		b.layer.shadowRadius = 0.0;
	
	UIButton* b = (UIButton*)sender;
	b.layer.shadowRadius = 10.0;
	b.layer.shadowColor = [UIColor yellowColor].CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
	
	// Applogies in advance this is a pretty hacky solution
	// I'm stealing the "accessibility label" property of the button to
	// store the pen weight the button represents
	if(self.delegate)
		[self.delegate penWeightChanged:[b.accessibilityLabel intValue]];

}

- (void)setToDefaults
{
	[self setColor:self.defaultColorButton];
	[self setWeight:self.defaultWeightButton];
}

@end
