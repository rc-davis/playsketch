/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSSceneViewController.h"
#import "PSDataModel.h"
#import "PSAnimationRenderingController.h"
#import "PSDrawingEventsView.h"
#import "PSSelectionHelper.h"
#import "PSSRTManipulator.h"
#import "PSHelpers.h"
#import "PSTimelineSlider.h"
#import "PSGroupOverlayButtons.h"
#import "PSVideoExportControllerViewController.h"
#import "PSMotionPathView.h"
#import "PSRecordingSession.h"
#import <QuartzCore/QuartzCore.h>

#define SELECTION_PEN_COLOR ([PSHelpers colorToInt64:[UIColor colorWithRed:1.0 green:0.0 blue:0.5 alpha:1.0]])
#define SELECTION_PEN_WEIGHT 2



@interface PSSceneViewController ()
@property(nonatomic)BOOL isSelecting; // If we are selecting instead of drawing
@property(nonatomic)BOOL isErasing;
@property(nonatomic)BOOL isReadyToRecord; // If manipulations should be treated as recording
@property(nonatomic)BOOL isRecording;
@property(nonatomic,retain) PSSelectionHelper* selectionHelper;
@property(nonatomic,retain) UIPopoverController* penPopoverController;
@property(nonatomic,retain) PSPenColorViewController* penController;
@property(nonatomic) UInt64 currentColor; // the drawing color as an int
@property(nonatomic) int penWeight;
@property(nonatomic,retain) PSRecordingSession* recordingSession;
- (void)refreshManipulatorLocation;
- (void)highlightButton:(UIButton*)b on:(BOOL)highlight;
@end



@implementation PSSceneViewController

/*
 ----------------------------------------------------------------------------
 UIViewController subclass methods
 These are part of the lifecycle of a viewcontroller and give us the 
 opportunity to do some logic each time we are loaded or unloaded for example
 ----------------------------------------------------------------------------
 */


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Add the renderingview to our viewcontroller hierarchy
	[self addChildViewController:self.renderingController];
	[self.renderingController viewDidLoad];
	
	// Start off in drawing mode
	self.isReadyToRecord = NO;
	self.isRecording = NO;
	[self startDrawing:nil];

	
	// Create the manipulator
	self.manipulator = [[PSSRTManipulator alloc] initAtLocation:CGPointZero];
	[self.renderingController.view addSubview:self.manipulator];
	self.manipulator.delegate = self;
	self.manipulator.hidden = YES;
	self.manipulator.groupButtons = self.selectionOverlayButtons;
	
	// Initialize to be drawing with an initial color
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SketchInterface" bundle:nil];
	self.penController = [storyboard instantiateViewControllerWithIdentifier:@"PenController"];
	self.penController.delegate = self;
	self.penPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.penController];
	[self.penController setToDefaults];
	
	
	// initialize our objects to the right time
	[self.renderingController jumpToTime:self.timelineSlider.value];
		
	// Create motion paths to illustrate our objects
	for (PSDrawingGroup* child in self.rootGroup.children)
		[self.motionPathView addLineForGroup:child];

}


- (void)viewDidUnload
{
    [super viewDidUnload];
	
	//TODO: zero out our references
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


-(void) viewWillDisappear:(BOOL)animated
{
	// Save a preview image of our drawing before going away!
	// First we snapshot the contents of our rendering view,
	// Then we convert that to a format that will fit in our data store
	// TODO: the last line of this seems to take a while....
	// TODO: downsample?
	// Only do this is if we are the root group for the document
	if (self.currentDocument.rootGroup == self.rootGroup)
	{
		GLKView* view = (GLKView*)self.renderingController.view;
		UIImage* previewImg = [view snapshot];
		UIImage* previewImgSmall = [PSHelpers imageWithImage:previewImg scaledToSize:CGSizeMake(462, 300)];
		self.currentDocument.previewImage = UIImagePNGRepresentation(previewImgSmall);
		[PSDataModel save];
	}
}




/*
 ----------------------------------------------------------------------------
 IBActions for the storyboard
 (methods with a return type of "IBAction" can be triggered by buttons in the 
 storyboard editor
 ----------------------------------------------------------------------------
 */


-(IBAction)dismissSceneView:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)playPressed:(id)sender
{
	[self setPlaying:!self.timelineSlider.playing];
}


- (IBAction)timelineScrubbed:(id)sender
{
	self.timelineSlider.playing = NO;
	[self.renderingController jumpToTime:self.timelineSlider.value];
	[self refreshManipulatorLocation];
	self.motionPathView.hidden = NO;
}


- (IBAction)toggleRecording:(id)sender
{
	self.isReadyToRecord = ! self.isReadyToRecord;
}

- (IBAction)exportAsVideo:(id)sender
{
	//Push a new View Controller
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SketchInterface" bundle:nil];
	PSVideoExportControllerViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"VideoExportViewController"];
	vc.renderingController = self.renderingController;
	[vc setModalPresentationStyle:UIModalPresentationFormSheet];
	[self presentModalViewController:vc animated:YES];

}


- (IBAction)snapTimeline:(id)sender
{
	// Round it to the nearest frame and update the UI
	float beforeSnapping = self.timelineSlider.value;
	float afterSnapping = roundf(beforeSnapping * POSITION_FPS) / (float)POSITION_FPS;
	if(afterSnapping != beforeSnapping)
	{
		[self.timelineSlider setValue:afterSnapping animated:YES];
		[self timelineScrubbed:nil];
	}
}

- (IBAction)showPenPopover:(id)sender
{
	[self.penPopoverController presentPopoverFromRect:[sender frame]
											   inView:self.view
							 permittedArrowDirections:UIPopoverArrowDirectionUp
											 animated:YES];
	
}

- (IBAction)startSelecting:(id)sender
{
	[self highlightButton:self.startSelectingButton on:YES];
	[self highlightButton:self.startDrawingButton on:NO];
	[self highlightButton:self.startErasingButton on:NO];
	self.isSelecting = YES;
	self.isErasing = NO;	
}

- (IBAction)startDrawing:(id)sender
{
	[self highlightButton:self.startSelectingButton on:NO];
	[self highlightButton:self.startDrawingButton on:YES];
	[self highlightButton:self.startErasingButton on:NO];
	self.isSelecting = NO;
	self.isErasing = NO;
}

- (IBAction)startErasing:(id)sender
{
	[self highlightButton:self.startSelectingButton on:NO];
	[self highlightButton:self.startDrawingButton on:NO];
	[self highlightButton:self.startErasingButton on:YES];
	self.isSelecting = NO;
	self.isErasing = YES;
}


- (IBAction)deleteCurrentSelection:(id)sender
{
	[self.rootGroup deleteSelectedChildren];
	self.selectionHelper = nil;
	self.manipulator.hidden = YES;
}

- (IBAction)createGroupFromCurrentSelection:(id)sender
{
	[PSHelpers assert:(self.selectionHelper.selectedGroupCount > 1)
		  withMessage:@"Need more than one existing group to create a new one"];
	
	PSDrawingGroup* newGroup = [self.rootGroup mergeSelectedChildrenIntoNewGroup];

	// Insert new keyframe
	SRTPosition newPosition = SRTPositionZero();
	newPosition.timeStamp = self.timelineSlider.value;
	[newGroup addPosition:newPosition withInterpolation:NO];
	
	[newGroup centerOnCurrentBoundingBox];
	[newGroup jumpToTime:self.timelineSlider.value];
	
	self.selectionHelper = nil;
	self.manipulator.hidden = YES;
	
}


- (IBAction)ungroupFromCurrentSelection:(id)sender
{
	PSDrawingGroup* topLevelGroup = [self.rootGroup topLevelSelectedChild];
	[PSHelpers assert:(topLevelGroup!=nil) withMessage:@"Need a non-nil child"];
	[PSHelpers assert:(topLevelGroup!=self.rootGroup) withMessage:@"Selected child can't be the root"];
	[topLevelGroup breakUpGroupAndMergeIntoParent];
}


- (IBAction)undo:(id)sender
{
	[PSDataModel undo];
	[self.rootGroup jumpToTime:self.timelineSlider.value];
}

- (IBAction)redo:(id)sender
{
	[PSDataModel redo];
	[self.rootGroup jumpToTime:self.timelineSlider.value];
}



- (void)setPlaying:(BOOL)playing
{
	if(!playing && self.timelineSlider.playing)
	{
		// PAUSE
		[self.renderingController stopPlaying];
		self.timelineSlider.playing = NO;
		[self refreshManipulatorLocation];
		self.motionPathView.hidden = NO;
	}
	else if(playing && !self.timelineSlider.playing)
	{
		// PLAY!
		// TODO: unselect things
		float time = self.timelineSlider.value;
		[self.renderingController playFromTime:time];
		self.timelineSlider.value = time;
		self.timelineSlider.playing = YES;
		if(!self.isRecording)
			self.motionPathView.hidden = YES;
	}
}


/*
 ----------------------------------------------------------------------------
 Private functions
 (they are private because they are declared at the top of this file instead of
 in the .h file)
 ----------------------------------------------------------------------------
 */

- (void)refreshManipulatorLocation
{
	if (self.selectionHelper.selectedGroupCount == 1)
	{
		PSDrawingGroup* group = [self.rootGroup topLevelSelectedChild];
		self.manipulator.center = [group currentOriginInWorldCoordinates];
	}
	else
	{
		self.manipulator.center = CGPointZero;
	}
}

- (void)highlightButton:(UIButton*)b on:(BOOL)highlight
{
	if(highlight)
	{
		b.layer.shadowRadius = 10.0;
		b.layer.shadowColor = [UIColor whiteColor].CGColor;
		b.layer.shadowOffset = CGSizeMake(0,0);
		b.layer.shadowOpacity = 1.0;
	}
	else
	{
		b.layer.shadowRadius = 0.0;
		b.layer.shadowOpacity = 0.0;
	}
}


/*
 ----------------------------------------------------------------------------
 Property Setters
 @synthesize generates a default pair of get/set methods
 You can override any of them here to customize behavior
 These are also called if you use dot-notaion: foo.currentDocument
 ----------------------------------------------------------------------------
 */


-(void)setCurrentDocument:(PSDrawingDocument *)currentDocument
{
	_currentDocument = currentDocument;
	//Also tell the rendering controller about the document to render it
	self.renderingController.currentDocument = currentDocument;
}

-(void)setRootGroup:(PSDrawingGroup *)rootGroup
{
	_rootGroup = rootGroup;
	//Also tell the rendering controller about the group to render it
	self.renderingController.rootGroup = rootGroup;
}


-(void)setSelectionHelper:(PSSelectionHelper *)selectionHelper
{
	if(selectionHelper == nil)
		self.manipulator.hidden = YES;
	
	//TODO: if the selection helper is going away, zero out its selections!	
	_selectionHelper = selectionHelper;
}



- (void)setIsReadyToRecord:(BOOL)isReadyToRecord
{
	if(_isReadyToRecord && !isReadyToRecord)
	{
		//Stop Recording
		[self.selectionOverlayButtons stopRecordingMode];
	}
	
	if(!_isReadyToRecord && isReadyToRecord)
	{
		//Start Recording
		[self.selectionOverlayButtons startRecordingMode];
	}
	
	_isReadyToRecord = isReadyToRecord;
}


/*
 ----------------------------------------------------------------------------
 PSDrawingEventsViewDrawingDelegate methods
 (Called by our drawing view when it needs to do something with touch events)
 ----------------------------------------------------------------------------
 */


/*	
 Provide a PSDrawingLine based on whether we are selecting or drawing
 */
-(PSDrawingLine*)newLineToDrawTo:(id)drawingView
{
	// Clear any current selection
	self.selectionHelper = nil;
	
	// No line necessary if we are erasing
	if (self.isErasing) return nil;
	
	// Create a new TEMPORARY line with the current color and weight
	// Read the comments on newTemporaryLineWithWeight:andColor: for an explanation
	// of why this line has to be "temporary"
	int weight = self.isSelecting ? SELECTION_PEN_WEIGHT : self.penWeight;
	UInt64 color = self.isSelecting ? SELECTION_PEN_COLOR : self.currentColor;
	PSDrawingLine* newLine = [PSDataModel newTemporaryLineWithWeight:weight andColor:color];
	
	// Start a new selection set helper to keep track of what's being selected
	if (self.isSelecting)
		self.selectionHelper = [PSSelectionHelper selectionWithRootGroup:self.rootGroup];
		
	// Tell the rendering controller to draw this line specially, since it isn't added to the scene yet
	self.renderingController.currentLine = newLine;

	return newLine;
}


-(void)addedToLine:(PSDrawingLine*)line fromPoint:(CGPoint)from toPoint:(CGPoint)to inDrawingView:(id)drawingView
{
	if (self.isSelecting)
	{
		// Give this new line segment to the selection helper to update the selected set
		
		// We want to add this line to the selectionHelper on a background
		// thread so it won't block the redrawing as much as possible
		// That requires us to bundle up the points as objects instead of structs
		// so they'll fit in a dictionary to pass to the performSelectorInBackground method
		// This is ugly-looking, but the arguments need to be on the heap instead of the stack
		NSDictionary* pointsDict = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSValue valueWithCGPoint:from], @"from",
									[NSValue valueWithCGPoint:to], @"to", nil];
		[self.selectionHelper performSelectorInBackground:@selector(addLineFromDict:) withObject:pointsDict];
	}
}


-(void)finishedDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	if ( line && self.isSelecting )
	{
		[self.selectionHelper finishSelection];
		
		//Show the manipulator if it was worthwhile
		if(self.selectionHelper.selectedGroupCount == 0)
		{
			self.selectionHelper = nil;
		}
		else
		{
			self.manipulator.hidden = NO;
			[self.selectionOverlayButtons configureForSelection:self.selectionHelper];
			[self refreshManipulatorLocation];
		}

	}
	else if( line && !self.isSelecting)
	{
		// Create a new group for it
		PSDrawingGroup* newLineGroup = [PSDataModel newDrawingGroupWithParent:self.rootGroup];
		
		[PSDataModel makeTemporaryLinePermanent:line];
		line.group = newLineGroup;
		
		SRTPosition newPosition = SRTPositionZero();
		newPosition.timeStamp = self.timelineSlider.value;
		[newLineGroup addPosition:newPosition withInterpolation:NO];

		// Center it
		[line.group centerOnCurrentBoundingBox];
		[line.group jumpToTime:self.timelineSlider.value];

		// Save it
		[PSDataModel save];
	
	}
	
	self.renderingController.currentLine = nil;
}


-(void)cancelledDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	self.renderingController.currentLine = nil;
	if(self.selectionHelper) self.selectionHelper = nil;
}

-(void)movedAt:(CGPoint)p inDrawingView:(id)drawingView
{
	// We only care about this when we are erasing.
	// For drawing and selecting, we let the drawingView build a line
	if(self.isErasing)
	{
		[self.rootGroup eraseAtPoint:p];
	}
}


-(void)whileDrawingLine:(PSDrawingLine *)line tappedAt:(CGPoint)p tapCount:(int)tapCount inDrawingView:(id)drawingView
{
	// Look to see if we tapped on an object!
	PSSelectionHelper* tapSelection = [PSSelectionHelper selectionForTap:p inRootGroup:self.rootGroup];
	if(tapCount == 1 && tapSelection.selectedGroupCount > 0)
	{
		// Treat this like a selection!
		self.renderingController.currentLine = nil;
		self.selectionHelper = tapSelection;
		self.manipulator.hidden = NO;
		[self.selectionOverlayButtons configureForSelection:self.selectionHelper];
		[self refreshManipulatorLocation];
	}
	else
	{
		// Didn't hit anything, so it's not a successful selection
		// Just treat it like a normal line that finished
		[self finishedDrawingLine:line inDrawingView:drawingView];
	}


}

/*
 ----------------------------------------------------------------------------
 PSSRTManipulatoDelegate methods
 Called by our manipulator(s) when they are manipulated
 ----------------------------------------------------------------------------
 */

-(void)manipulatorDidStartInteraction:(id)sender
						willTranslate:(BOOL)isTranslating
						   willRotate:(BOOL)isRotating
							willScale:(BOOL)isScaling
{
	if(self.isReadyToRecord)
	{
		self.isRecording = YES;
	
		self.recordingSession = [self.rootGroup startSelectedGroupsRecordingTranslation:isTranslating
																			   rotation:isRotating
																				scaling:isScaling
																				 atTime:self.timelineSlider.value];
		// Start playing the timeline
		[self setPlaying:YES];
		self.selectionOverlayButtons.recordPulsing = YES;
	}
	
	// We would like to keep the motion paths updating in realtime while we
	// record, but that's too expensive until we optimize the path updating
	// So instead we just hide
	self.motionPathView.hidden = YES;
	
}

-(void)manipulator:(id)sender
   didTranslateByX:(float)dX
			andY:(float)dY
		  rotation:(float)dRotation
			 scale:(float)dScale
	 isTranslating:(BOOL)isTranslating
		isRotating:(BOOL)isRotating
		 isScaling:(BOOL)isScaling
	  timeDuration:(float)duration
{

	if (self.isRecording)
	{
		[self.recordingSession transformAllGroupsByX:dX
												andY:dY
											rotation:dRotation
											   scale:dScale
											  atTime:self.timelineSlider.value];
	}
	else
	{

		SRTKeyframeType keyframeType =  self.isRecording ?
											SRTKeyframeTypeNone() :
											SRTKeyframeMake(isScaling, isRotating, isTranslating);

		[self.rootGroup transformSelectionByX:dX
										 andY:dY
									 rotation:dRotation
										scale:dScale
									   atTime:self.timelineSlider.value
							   addingKeyframe:keyframeType
						   usingInterpolation:YES];
	}
}

-(void)manipulatorDidStopInteraction:(id)sender
					  wasTranslating:(BOOL)isTranslating
						 wasRotating:(BOOL)isRotating
						  wasScaling:(BOOL)isScaling
						withDuration:(float)duration
{
	
	if(self.isRecording)
	{
		self.isRecording = NO;

		// Before we add our last keyframe, snap the timeline so our keyframe
		// will be easy to scrub to later
		[self snapTimeline:nil];


		[self.recordingSession finishAtTime:self.timelineSlider.value];
		
		// Stop playing
		[self setPlaying:NO];
		self.selectionOverlayButtons.recordPulsing = NO;
	}
	
	// We would rather be doing this real-time instead of at the end of the interaction
	// TODO: fix up motion paths!
	//	[self.motionPathView addLineForGroup:manipulator.group];
	self.motionPathView.hidden = NO;
	
	//TODO: this should only be called if something changed?
	[self.rootGroup applyToSelectedSubTrees:^(PSDrawingGroup *g) {[g doneMutatingPositions];}];
}


/*
 ----------------------------------------------------------------------------
 PSPenColorChangeDelegate methods
 Called by when our pen colours change
 ----------------------------------------------------------------------------
 */
-(void)penColorChanged:(UIColor*)newColor
{
	self.currentColor = [PSHelpers colorToInt64:newColor];
	self.startDrawingButton.backgroundColor = newColor;
	[self startDrawing:nil];
	if(self.penPopoverController && self.penPopoverController.popoverVisible)
		[self.penPopoverController dismissPopoverAnimated:YES];
}

-(void)penWeightChanged:(int)newWeight
{
	self.penWeight = newWeight;
	[self startDrawing:nil];
	if(self.penPopoverController && self.penPopoverController.popoverVisible)
		[self.penPopoverController dismissPopoverAnimated:YES];
}


@end

