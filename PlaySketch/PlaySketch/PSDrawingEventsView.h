/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <GLKit/GLKit.h>
#import "PSDrawingGroup.h"
#import "PSDrawingLine.h"
#import "PSAnimationRenderingController.h"

@interface PSDrawingEventsView : GLKView

//@property(nonatomic,weak) IBOutlet PSAnimationRenderingController* parentController;
@property(nonatomic,retain)PSDrawingGroup* currentDrawingGroup;
@property(nonatomic,retain)PSDrawingLine* currentLine;

@end
