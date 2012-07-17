/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#define MANIPULATOR_WIDTH 200


#import <UIKit/UIKit.h>
#import "PSDrawingEventsView.h"
@class PSAnimationRenderingController;
@class PSDrawingDocument;
@class PSSRTManipulator;



@interface PSSceneViewController : UIViewController <PSDrawingEventsViewDrawingDelegate>

@property(nonatomic,retain)IBOutlet PSAnimationRenderingController* renderingController;
@property(nonatomic,retain)IBOutlet PSDrawingEventsView* drawingTouchView;
@property(nonatomic,retain)PSDrawingDocument* currentDocument;
@property(nonatomic,retain)PSSRTManipulator* manipulator;

-(IBAction)play:(id)sender;
-(IBAction)dismissSceneView:(id)sender;
-(IBAction)toggleCharacterCreation:(id)sender;

@end
