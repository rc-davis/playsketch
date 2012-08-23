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
@class PSAnimationRenderingController, PSDrawingDocument, PSTimelineSlider, PSGroupOverlayButtons, PSMotionPathView;



@interface PSSceneViewController : UIViewController <PSDrawingEventsViewDrawingDelegate, 
														PSSRTManipulatoDelegate>

@property(nonatomic,retain) IBOutlet PSAnimationRenderingController* renderingController;
@property(nonatomic,retain) IBOutlet PSDrawingEventsView* drawingTouchView;
@property(nonatomic,retain) IBOutlet UIButton* createCharacterButton;
@property(nonatomic,retain) IBOutlet UIButton* playButton;
@property(nonatomic,retain) IBOutlet UIButton* initialColorButton;
@property(nonatomic,retain) IBOutlet PSTimelineSlider* timelineSlider;
@property(nonatomic,retain) IBOutlet PSGroupOverlayButtons* selectionOverlayButtons;
@property(nonatomic,retain) IBOutlet PSMotionPathView* motionPathView;
@property(nonatomic,retain) PSDrawingDocument* currentDocument;
@property(nonatomic,retain) PSDrawingGroup* rootGroup;

- (IBAction)dismissSceneView:(id)sender;
- (IBAction)setColor:(id)sender;
- (IBAction)startSelecting:(id)sender;
- (IBAction)createCharacterWithCurrentSelection:(id)sender;
- (IBAction)deleteCurrentSelection:(id)sender;
- (IBAction)playPressed:(id)sender;
- (IBAction)timelineScrubbed:(id)sender;
- (IBAction)toggleRecording:(id)sender;
- (IBAction)showDetailsForSelection:(id)sender;
- (IBAction)exportAsVideo:(id)sender;
- (IBAction)snapTimeline:(id)sender;
- (void)setPlaying:(BOOL)playing;

@end
