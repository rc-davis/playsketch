/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#define PSANIM_BACKGROUND_COLOR 1.0, 0.977, 0.842, 1.00
#define PSANIM_LINE_COLOR 0.5, 0.35, 0, 1.0
#define PSANIM_SELECTION_LOOP_COLOR 1.000, 1.000, 0.012, 1.0
#define PSANIM_SELECTED_LINE_COLOR 0.933, 0.000, 0.012, 0.6
#define SELECTION_PEN_COLOR ([UIColor colorWithRed:1.0 green:0.0 blue:0.5 alpha:1.0])
#define SELECTION_PEN_WEIGHT 2


#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "PSDrawingGroup.h"
#import "PSDrawingLine.h"
#import "PSSelectionHelper.h"


@interface PSAnimationRenderingController : GLKViewController

@property(nonatomic,retain) PSDrawingDocument* currentDocument;
@property(nonatomic,retain) PSDrawingGroup* rootGroup;
@property(nonatomic,retain) PSDrawingLine* currentLine;
@property(nonatomic, readonly)int currentFrame; // the time frame that we are at right now
@property(nonatomic)BOOL playing;
- (void)playFromTime:(float)frame;
- (void)jumpToTime:(float)time;
- (void)stopPlaying;
- (void)update;
@end


// Use categories to add a render and animation function to our drawing items
@interface PSDrawingGroup ( renderingCategory )
- (void)jumpToTime:(float)time;
- (void)renderGroupWithMatrix:(GLKMatrix4)parentModelMatrix uniforms:(GLint*)uniforms overrideColor:(BOOL)overrideColor;
- (void)updateWithTimeInterval:(NSTimeInterval)timeSinceLastUpdate toTime:(NSTimeInterval)currentTime;
@end

@interface PSDrawingLine ( renderingCategory )
- (void) renderWithUniforms:(GLint*)uniforms overrideColor:(BOOL)overrideColor;
@end

