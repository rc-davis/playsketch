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
#import "PSGraphicConstants.h"

@implementation PSPenColorViewController

- (IBAction)setColor:(id)sender
{
	for (UIButton* b in self.colorButtons)
		b.layer.shadowRadius = 0.0;


	UIButton* b = (UIButton*)sender;
	b.layer.shadowRadius = 10.0;
	b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
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
	b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
	
	// Applogies in advance this is a pretty hacky solution
	// Stealing the "tag" function to store an integer value for the weight the pen should represent
	// Lets us set the pen weights in interface builder
	if(self.delegate)
		[self.delegate penWeightChanged:b.tag];

}

- (void)setToDefaults
{
	[self setColor:self.defaultColorButton];
	[self setWeight:self.defaultWeightButton];
}

@end
