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

@interface PSSceneViewController ()
@property(nonatomic)BOOL isSelecting; // If we are selecting instead of drawing
@property(nonatomic,retain) PSSelectionHelper* selectionHelper;
@property(nonatomic,retain) PSDrawingGroup* selectionGroup;
@property(nonatomic) UInt64 currentColor; // the drawing color as an int
- (PSSRTManipulator*)createManipulatorForGroup:(PSDrawingGroup*)group;
- (void)removeManipulatorForGroup:(PSDrawingGroup*)group;
- (PSSRTManipulator*)manipulatorForGroup:(PSDrawingGroup*)group;
@end



@implementation PSSceneViewController
@synthesize renderingController = _renderingController;
@synthesize drawingTouchView = _drawingTouchView;
@synthesize startDrawingButton = _startDrawingButton;
@synthesize startSelectingButton = _startSelectingButton;
@synthesize createCharacterButton = _createCharacterButton;
@synthesize playButton = _playButton;
@synthesize timelineSlider = _timelineSlider;
@synthesize currentDocument = _currentDocument;
@synthesize isSelecting = _isSelecting;
@synthesize selectionHelper = _selectionHelper;
@synthesize selectionGroup = _selectionGroup;
@synthesize currentColor = _currentColor;




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
	
	//Start off in drawing mode
	self.isSelecting = NO;
	self.startDrawingButton.enabled = NO;
	self.startSelectingButton.enabled = YES;
	self.currentColor = [PSHelpers colorToInt64:[UIColor colorWithRed:0.2 
																green:0.2 
																 blue:0.2 
																alpha:1.0]];	

	self.createCharacterButton.enabled = NO;
	

	//Create manipulator views for our current document's children
	for (PSDrawingGroup* child in self.currentDocument.rootGroup.children)
		[self createManipulatorForGroup:child];
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
	GLKView* view = (GLKView*)self.renderingController.view;
	UIImage* previewImg = [view snapshot];
	UIImage* previewImgSmall = [PSHelpers imageWithImage:previewImg scaledToSize:CGSizeMake(462, 300)];
	self.currentDocument.previewImage = UIImagePNGRepresentation(previewImgSmall);
	[PSDataModel save];
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


-(IBAction)startDrawing:(id)sender
{
	self.startDrawingButton.enabled = NO;
	self.startSelectingButton.enabled = YES;
	self.isSelecting = NO;
	if(self.selectionHelper)
	{
		self.selectionHelper = nil;
		self.createCharacterButton.enabled = NO;
	}
	
	self.selectionGroup = nil;
}


-(IBAction)startSelecting:(id)sender
{
	self.startDrawingButton.enabled = YES;
	self.startSelectingButton.enabled = NO;	
	self.isSelecting = YES;	
}


- (IBAction)setColor:(id)sender
{
	// Grab the background color of the button that called us and remember it
	UIColor* c = [sender backgroundColor];
	self.currentColor = [PSHelpers colorToInt64:c];
}


- (IBAction)createCharacterWithCurrentSelection:(id)sender
{
	[PSHelpers assert:(self.selectionGroup != nil) withMessage:@"need a selection to make character"];
	
	// Keep the selection group by not flattening it when it is unselected
	self.selectionGroup.explicitCharacter = [NSNumber numberWithBool:YES];
}


- (IBAction)playPressed:(id)sender
{
	[self.renderingController playFromTime:0.00];
	self.timelineSlider.value = 0;
}


- (IBAction)timelineScrubbed:(id)sender
{
	[self.renderingController jumpToTime:self.timelineSlider.value];
}


/*
 ----------------------------------------------------------------------------
 Private functions
 (they are private because they are declared at the top of this file instead of
 in the .h file)
 ----------------------------------------------------------------------------
 */


- (PSSRTManipulator*)createManipulatorForGroup:(PSDrawingGroup*)group
{

	// Figure out the frame & its offsets at the current time
	CGRect groupFrame = [group boundingRect];
	SRTPosition groupPosition;
	[group getStateAtTime:0 position:&groupPosition rate:nil helperIndex:nil]; //TODO: not 0!
	groupFrame.origin.x += groupPosition.location.x;
	groupFrame.origin.y += groupPosition.location.y;
	//TODO: need to take scale and rotation into account here.
	
	// Create the manipulator & set its location
	PSSRTManipulator* man = [[PSSRTManipulator alloc] initWithFrame:groupFrame];
	[self.renderingController.view addSubview:man];
	man.delegate = self;
	man.group = group;

	return man;
}

- (void)removeManipulatorForGroup:(PSDrawingGroup*)group
{
	PSSRTManipulator* groupMan = [self manipulatorForGroup:group];
	[PSHelpers assert:(groupMan != nil) withMessage:@"removeManipulator for group without one!"];
	[groupMan removeFromSuperview];
}

- (PSSRTManipulator*)manipulatorForGroup:(PSDrawingGroup*)group
{
	// Find the manipulator by searching through the rendering view
	PSSRTManipulator* groupMan = nil;
	for (UIView* v in self.renderingController.view.subviews)
	{
		if ([v class] == [PSSRTManipulator class])
		{
			PSSRTManipulator* man = (PSSRTManipulator*)v;
			if ([man group] == group)
			{
				groupMan = man;
				break;
			}
		}
	}
	return groupMan;
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
	//Also tell the rendering controller about the group to render it
	self.renderingController.rootGroup = currentDocument.rootGroup;
	
}


-(void)setSelectionHelper:(PSSelectionHelper *)selectionHelper
{
	_selectionHelper = selectionHelper;
	//Also tell the rendering controller about the selection helper so it can draw the loupe and highlight objects
	self.renderingController.selectionHelper = selectionHelper;
}


- (void)setSelectionGroup:(PSDrawingGroup *)selectionGroup
{
	if (selectionGroup == _selectionGroup)
		return;
	
	// De select the current one
	if (_selectionGroup)
	{
		PSSRTManipulator* oldManipulator = [self manipulatorForGroup:_selectionGroup];
		if(oldManipulator)
			oldManipulator.selected = NO;
		
		// Merge it back into the parent if it hasn't been explicitly made a character
		if([_selectionGroup.explicitCharacter boolValue] == NO)
		{
			[self removeManipulatorForGroup:_selectionGroup];
			[PSDataModel mergeGroup:_selectionGroup intoParentAtTime:0];//TODO: real time
		}		
	}
	
	_selectionGroup = selectionGroup;
	
	// Start the new one being selected
	if ( selectionGroup )
	{
		PSSRTManipulator* newManipulator = [self manipulatorForGroup:selectionGroup];
		if (newManipulator)
			newManipulator.selected = YES;
	}
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
	if(self.selectionHelper)
	{
		self.selectionHelper = nil;
		self.createCharacterButton.enabled = NO;
	}
	
	self.selectionGroup = nil;

	
	if (! self.isSelecting )
	{
		PSDrawingLine* line = [PSDataModel newLineInGroup:self.currentDocument.rootGroup];
		line.color = [NSNumber numberWithUnsignedLongLong:self.currentColor];
		return line;
	}
	else
	{
		// Create a line to draw
		PSDrawingLine* selectionLine = [PSDataModel newLineInGroup:nil];
		selectionLine.color = [NSNumber numberWithUnsignedLongLong:[PSHelpers colorToInt64:[UIColor redColor]]];
		
		// Start a new selection set helper
		self.selectionHelper = [[PSSelectionHelper alloc] initWithGroup:self.currentDocument.rootGroup
																	 andLine:selectionLine];		
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
		if(self.selectionHelper.selectedLines.count > 0)
		{
			self.createCharacterButton.enabled = YES;
			
			// create a new group for the lines
			self.selectionGroup = [PSDataModel newChildOfGroup:self.currentDocument.rootGroup
												   withLines:self.selectionHelper.selectedLines];
			
			[self.selectionGroup jumpToTime:0]; //TODO: right frame!
			
			// create a new manipulator for the new group
			PSSRTManipulator* newMan = [self createManipulatorForGroup:self.selectionGroup];
			newMan.selected = YES;
			
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




/*
 ----------------------------------------------------------------------------
 PSSRTManipulatoDelegate methods
 Called by our manipulator(s) when they are manipulated
 ----------------------------------------------------------------------------
 */

-(void)manipulatorDidStartInteraction:(id)sender
{
	PSSRTManipulator* manipulator = sender;
	[manipulator setSelected:YES];
	self.selectionGroup = manipulator.group;
}

-(void)manipulator:(id)sender didUpdateBy:(CGAffineTransform)incrementalTransform toTransform:(CGAffineTransform)fullTransform
{
	PSSRTManipulator* manipulator = sender;

	//turn the current full transform into an S,R,T Position
	SRTPosition position = SRTPositionFromTransform(fullTransform);

	//Store the position at the current time
	position.frame = 0; //TODO: pick current time
	[manipulator.group addPosition:position];
	
	//Refresh the display of the object
	[manipulator.group jumpToTime:0]; //TODO: pick current time
}

@end
