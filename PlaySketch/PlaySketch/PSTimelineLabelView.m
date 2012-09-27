/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSTimelineLabelView.h"
#import "PSTimelineSlider.h"
#import "PSGraphicConstants.h"


@implementation PSTimelineLabelView


- (void)setLabelsForTimelineSlider:(PSTimelineSlider*)slider
{
	// Get rid of the old labels
	for (UIView* v in self.subviews)
		[v removeFromSuperview];

	// Add some new ones
	int maxSecond = floor(slider.maximumValue);
	float WIDTH = 20.0;
	CGRect r = CGRectMake(0, 0, WIDTH, self.frame.size.height);
	
	int stepSize = 1;
	if (maxSecond <= 5) stepSize = 1;
	else if(maxSecond <= 20) stepSize = 2;
	else if(maxSecond <= 40) stepSize = 5;
	else if(maxSecond <= 75) stepSize = 10;
	else if(maxSecond <= 120) stepSize = 15;
	else stepSize = 30;

	for(int i = 0; i <= maxSecond; i += stepSize)
	{
		r.origin.x = [slider xOffsetForTime:(float)i] - WIDTH/2.0;
		UILabel* label = [[UILabel alloc] initWithFrame:r];
		label.text = [NSString stringWithFormat:@"%d", i];
		label.textAlignment = NSTextAlignmentCenter;
		label.textColor = TIMELINE_LABEL_UICOLOR;
		label.backgroundColor = TIMELINE_BACKGROUND_UICOLOR;
		[self addSubview:label];
	}
}


@end
