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
#import <QuartzCore/QuartzCore.h>


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
- (void)refreshManipulatorLocation;
- (void)highlightButton:(UIButton*)b on:(BOOL)highlight;
@end



@implementation PSSceneViewController
@synthesize renderingController = _renderingController;
@synthesize drawingTouchView = _drawingTouchView;
@synthesize playButton = _playButton;
@synthesize timelineSlider = _timelineSlider;
@synthesize selectionOverlayButtons = _selectionOverlayButtons;
@synthesize motionPathView = _motionPathView;
@synthesize currentDocument = _currentDocument;
@synthesize rootGroup = _rootGroup;
@synthesize isSelecting = _isSelecting;
@synthesize isReadyToRecord = _isReadyToRecord;
@synthesize isRecording = _isRecording;
@synthesize selectionHelper = _selectionHelper;
@synthesize penPopoverController = _penPopoverController;
@synthesize penController = _penController;
@synthesize currentColor = _currentColor;
@synthesize penWeight = _penWeight;
@synthesize manipulator = _manipulator;




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
	[self.renderingController.view insertSubview:self.manipulator belowSubview:self.selectionOverlayButtons];
	self.manipulator.delegate = self;
	self.manipulator.hidden = YES;
	
	
	// Initialize to be drawing with an initial color
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SketchInterface" bundle:nil];
	self.penController = [storyboard instantiateViewControllerWithIdentifier:@"PenController"];
	self.penController.delegate = self;
	self.penPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.penController];
	[self.penController setToDefaults];
	

	[self.selectionOverlayButtons hide:NO];
	
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
	self.manipulator.center = CGPointMake(0,0);
	
	// TODO:
	//CGPointMake(m.group.currentCachedPosition.location.x, m.group.currentCachedPosition.location.y);
	//-		[self.selectionOverlayButtons setLocation: newPoint];
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
	//Also tell the rendering controller about the selection helper so it can draw the loupe and highlight objects
	self.renderingController.selectionHelper = selectionHelper;
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
	//Clear out any old selection state
	self.selectionHelper = nil;
	
	if (self.isErasing) return nil;
	
	if (! self.isSelecting)
	{
		// Creating a new line!
		// Every line gets put into a new group of its own, directly under self.rootGroup
		
		PSDrawingGroup* newLineGroup = [PSDataModel newDrawingGroupWithParent:self.rootGroup];
		PSDrawingLine* line = [PSDataModel newLineInGroup:newLineGroup withWeight:self.penWeight];
		line.color = [NSNumber numberWithUnsignedLongLong:self.currentColor];
		return line;
	}
	else
	{
		// Create a selection line to draw with
		// TODO: this shouldn't be part of the model since it screws up the undo/redo
		PSDrawingLine* selectionLine = [PSDataModel newLineInGroup:nil withWeight:2];
		selectionLine.color = [NSNumber numberWithUnsignedLongLong:[PSHelpers colorToInt64:[UIColor redColor]]];
		
		// Start a new selection set helper
		self.selectionHelper = [[PSSelectionHelper alloc] initWithGroup:self.rootGroup
													   andSelectionLine:selectionLine];
		return selectionLine;
	}
		
}


-(void)addedToLine:(PSDrawingLine*)line fromPoint:(CGPoint)from toPoint:(CGPoint)to inDrawingView:(id)drawingView
{
	
	if ( line == self.selectionHelper.selectionLoupeLine )
	{
		// Give this new line segment to the selection helper to update the selected set
		
		// We want to add this line to the selectionHelper on a background
		// thread so it won't block the redrawing as much as possible
		// That requires us to bundle up the points as objects instead of structs
		// so they'll fit in a dictionary to pass to the performSelectorInBackground method
		NSDictionary* pointsDict = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSValue valueWithCGPoint:from], @"from",
									[NSValue valueWithCGPoint:to], @"to", nil];
		[self.selectionHelper performSelectorInBackground:@selector(addLineFromDict:) withObject:pointsDict];
	}
}


-(void)finishedDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	if ( line == self.selectionHelper.selectionLoupeLine )
	{
		//Clean up selection state
		[PSDataModel deleteDrawingLine:self.selectionHelper.selectionLoupeLine];
		self.selectionHelper.selectionLoupeLine = nil;
		
		//Show the manipulator if it was worthwhile
		self.manipulator.hidden = NO;

		
		if(![self.selectionHelper anySelected])
		{
			self.selectionHelper = nil;
		}
		else
		{
			self.manipulator.hidden = NO;
			
		}
	}
	else
	{
		[PSDataModel save];
	}
}


-(void)cancelledDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	//TODO: similar to finishedDrawing
	[PSHelpers NYIWithmessage:@"scene controller view: cancelledDrawingLine"];
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
	
	PSSRTManipulator* manipulator = sender;
/*
	TODO: bring back recording!
 
	if(self.isReadyToRecord)
	{
		self.isRecording = YES;
		
		//Remember this location and clear everything after it
		SRTPosition currentPos = [manipulator.group currentCachedPosition];
		currentPos.timeStamp = self.timelineSlider.value;
		currentPos.keyframeType = SRTKeyframeMake(isScaling, isRotating, isTranslating);
		[manipulator.group addPosition:currentPos withInterpolation:NO];

		// Start playing the timeline
		[self setPlaying:YES];
		
		// Pause the group
		[manipulator.group pauseUpdatesOfTranslation:isTranslating
											rotation:(isRotating||isTranslating)
											   scale:(isScaling||isTranslating)];
		
		[manipulator.group flattenTranslation:isTranslating
								   rotation:(isRotating||isTranslating)
									  scale:(isScaling||isTranslating)
								  betweenTime:self.timelineSlider.value
									  andTime:1e99];

		self.selectionOverlayButtons.recordPulsing = YES;
	}
*/	
	
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
	PSSRTManipulator* manipulator = sender;
	
	// Clear out the frames we are overwriting if this is a recording!
/*
	TODO: fix up recording
	if( self.isRecording)
		[manipulator.group flattenTranslation:isTranslating
								   rotation:isRotating || isTranslating
									  scale:isScaling || isTranslating
								  betweenTime:self.timelineSlider.value - duration
									  andTime:self.timelineSlider.value];
*/

	for (PSDrawingGroup* g in self.rootGroup.children)
	{
		//TODO: recurse more than one level deep!
		
		if (g.isSelected)
		{
			// Get the group's position
			SRTPosition position = [g currentCachedPosition];
			
			// Update it with these changes
			position.location.x += dX;
			position.location.y += dY;
			position.rotation += dRotation;
			position.scale *= dScale;
			
			//Store the position at the current time
			position.timeStamp = self.timelineSlider.value;
			position.keyframeType = self.isRecording ? SRTKeyframeTypeNone() :
			SRTKeyframeMake(isScaling, isRotating, isTranslating);
			[g addPosition:position withInterpolation:!self.isRecording];
			
			[g setCurrentCachedPosition:position];
		}
	}
	
	//Keep our buttons properly aligned
	[self.selectionOverlayButtons setLocation:[manipulator upperRightPoint]];

	
}

-(void)manipulatorDidStopInteraction:(id)sender
					  wasTranslating:(BOOL)isTranslating
						 wasRotating:(BOOL)isRotating
						  wasScaling:(BOOL)isScaling
						withDuration:(float)duration
{
	PSSRTManipulator* manipulator = sender;

	/*
	if(self.isRecording)
	{
		self.isRecording = NO;
		
		// Before we add our last keyframe, snap the timeline so our keyframe
		// will be easy to scrub to later
		[self snapTimeline:nil];
		
		// Erase all the data after this point
		[manipulator.group flattenTranslation:isTranslating
									 rotation:isRotating || isTranslating
										scale:isScaling || isTranslating
								  betweenTime:self.timelineSlider.value - duration
									  andTime:1e100];
		
		// Put a marker at this location and stop playing
		SRTPosition currentPos = [manipulator.group currentCachedPosition];
		currentPos.timeStamp = self.timelineSlider.value;
		currentPos.keyframeType = SRTKeyframeMake(isScaling, isRotating, isTranslating);
		[manipulator.group addPosition:currentPos withInterpolation:NO];

		self.selectionOverlayButtons.recordPulsing = NO;
		
		// Unpause the group
		[manipulator.group unpauseAll];

		// Stop playing
		[self setPlaying:NO];

	}
	
	// We would rather be doing this real-time instead of at the end of the interaction
	[self.motionPathView addLineForGroup:manipulator.group];
	self.motionPathView.hidden = NO;
	*/
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

