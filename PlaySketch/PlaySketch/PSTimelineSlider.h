/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <UIKit/UIKit.h>

@class PSTimelineLabelView;

@interface PSTimelineSlider : UISlider
@property(nonatomic) BOOL playing; //starts and stops animation
@property(nonatomic,retain)IBOutlet PSTimelineLabelView* labelView;
- (float)xOffsetForTime:(float)time;
- (BOOL)nearEndOfTimeline:(float)time;
- (void)expandTimeline;
@end
