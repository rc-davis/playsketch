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
#import <GLKit/GLKit.h>
#import "PSDrawingGroup.h"
#import "PSDrawingLine.h"
#import "PSSelectionHelper.h"


@interface PSAnimationRenderingController : GLKViewController

@property(nonatomic,retain) PSDrawingDocument* currentDocument;
@property(nonatomic,retain) PSDrawingLine* currentLine;
@property(nonatomic)BOOL playing;
- (void)playFromTime:(float)frame;
- (void)jumpToTime:(float)time;
- (void)stopPlaying;
- (void)update;
@end


/*
 These are some methods we are adding to the DrawingGroup and DrawingLine classes.
 This lets us keep all the rendering-specific code in this file, while still accessing
 the private data to the data structures
*/
@interface PSDrawingGroup ( renderingCategory )
- (void)jumpToTime:(float)time;
- (void)renderGroupWithEffect:(GLKBaseEffect*)effect matrix:(GLKMatrix4)parentMatrix isSelected:(BOOL)isSelected;
- (void)updateWithTimeInterval:(NSTimeInterval)timeSinceLastUpdate toTime:(NSTimeInterval)currentTime;
@end

@interface PSDrawingLine ( renderingCategory )
- (void) renderWithEffect:(GLKBaseEffect*)effect isSelected:(BOOL)isSelected;
@end

