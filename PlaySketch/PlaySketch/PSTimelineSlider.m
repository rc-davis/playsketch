/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


#import "PSTimelineSlider.h"
@interface PSTimelineSlider ()
@property(nonatomic,retain)NSTimer* timer;
@end


@implementation PSTimelineSlider
@synthesize playing = _playing;
@synthesize timer = _timer;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{

    }
    return self;
}


- (void)awakeFromNib
{
	[self setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
}

-(void)setPlaying:(BOOL)playing
{
	if (playing && !_playing)
	{
		//create a new timer to update our animation
		self.timer = [NSTimer scheduledTimerWithTimeInterval:1/30.0
												  target:self
												selector:@selector(timerUpdate)
												userInfo:nil
												 repeats:YES];
	}
	else if (!playing && _playing)
	{
		[self.timer invalidate];
		self.timer = nil;
	}
	
	_playing = playing;
}

-(void)timerUpdate
{
	self.value += self.timer.timeInterval;
	
	if(self.value >= self.maximumValue)
		self.playing = NO;
}

@end
