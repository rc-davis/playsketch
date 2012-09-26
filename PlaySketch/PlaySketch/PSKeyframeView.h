/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <Foundation/Foundation.h>

@protocol PSKeyframeTimelineInfoProvider
- (float)xOffsetForTime:(float)time;
@end


@class PSDrawingGroup;

@interface PSKeyframeView : UIView
@property(nonatomic,weak)PSDrawingGroup* rootGroup;
@property(nonatomic,weak)IBOutlet id<PSKeyframeTimelineInfoProvider> infoProvider;

- (void)refreshAll;
@end
