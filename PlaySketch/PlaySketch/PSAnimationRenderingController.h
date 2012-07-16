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


@interface PSAnimationRenderingController : GLKViewController

@property(nonatomic,retain) PSDrawingGroup* rootGroup;
@property(nonatomic,retain) PSDrawingLine* selectionLoupeLine; 
@property(nonatomic,retain) NSSet* selectedLines;

@end


// Use categories to add a render function to our drawing items
// And an update function to our groups
@interface PSDrawingGroup ( renderingCategory )
- (void) renderGroupWithEffect:(GLKBaseEffect*)effect;
- (void) updateWithTimeInterval:(NSTimeInterval)timeSinceLastUpdate;
@end

@interface PSDrawingLine ( renderingCategory )
- (void) render;
@end

