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
#define PSANIM_LINE_COLOR 0.5, 0.5, 0.5, 1.0
#define PSANIM_SELECTION_LOOP_COLOR 1.0, 0.5, 0.0, 1.0
#define PSANIM_SELECTED_LINE_COLOR 1.0, 0.5, 0.0, 1.0
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "PSDrawingGroup.h"
#import "PSDrawingLine.h"
#import "PSSelectionHelper.h"


@interface PSAnimationRenderingController : GLKViewController

@property(nonatomic,retain) PSDrawingGroup* rootGroup;
@property(nonatomic,retain) PSSelectionHelper* selectionHelper; 

@end


// Use categories to add a render function to our drawing items
// And an update function to our groups
@interface PSDrawingGroup ( renderingCategory )
- (void)renderGroupWithMatrix:(GLKMatrix4)parentModelMatrix uniforms:(GLint*)uniforms;
- (void)updateWithTimeInterval:(NSTimeInterval)timeSinceLastUpdate;
@end

@interface PSDrawingLine ( renderingCategory )
- (void) render;
@end

