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
#import "PSDrawingEventsView.h"
#import "PSSRTManipulator.h"
@class PSAnimationRenderingController;
@class PSDrawingDocument;



@interface PSSceneViewController : UIViewController <PSDrawingEventsViewDrawingDelegate, 
														PSSRTManipulatoDelegate>

@property(nonatomic,retain)IBOutlet PSAnimationRenderingController* renderingController;
@property(nonatomic,retain)IBOutlet PSDrawingEventsView* drawingTouchView;
@property(nonatomic,retain)IBOutlet UIButton* startDrawingButton;
@property(nonatomic,retain)IBOutlet UIButton* startSelectingButton;
@property(nonatomic,retain)PSDrawingDocument* currentDocument;
@property(nonatomic,retain)PSSRTManipulator* selectedSetManipulator;

-(IBAction)dismissSceneView:(id)sender;
-(IBAction)startDrawing:(id)sender;
-(IBAction)startSelecting:(id)sender;

@end
