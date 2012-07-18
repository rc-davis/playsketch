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

@interface PSSceneViewController ()
@property(nonatomic)BOOL isSelecting; // If we are selecting instead of drawing
@end



@implementation PSSceneViewController
@synthesize renderingController = _renderingController;
@synthesize drawingTouchView = _drawingTouchView;
@synthesize currentDocument = _currentDocument;
@synthesize manipulator = _manipulator;
@synthesize isSelecting = _isSelecting;




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
	
	//Create a manipulator and add it to our rendering view
	//TODO: for now just with static size!
	CGRect manipulatorFrame = CGRectMake(0, 0, MANIPULATOR_WIDTH, MANIPULATOR_WIDTH);
	self.manipulator = [[PSSRTManipulator alloc] initWithFrame:manipulatorFrame];
	[self.renderingController.view addSubview:self.manipulator];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}




/*
 ----------------------------------------------------------------------------
 IBActions for the storyboard
 (methods with a return type of "IBAction" can be triggered by buttons in the storyboard editor
 ----------------------------------------------------------------------------
 */

-(IBAction)play:(id)sender
{
}


-(IBAction)dismissSceneView:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}


-(IBAction)toggleCharacterCreation:(id)sender
{
	//TODO: not necessary
	self.isSelecting = !self.isSelecting;
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
	self.renderingController.rootGroup = currentDocument.rootGroup;
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
	if (! self.isSelecting )
	{
		return [PSDataModel newLineInGroup:self.currentDocument.rootGroup];
	}
	else
	{
		// Create a line to draw
		PSDrawingLine* selectionLine = [PSDataModel newLineInGroup:nil];

		// Start a new selection set helper
		PSSelectionHelper* helper = [[PSSelectionHelper alloc] initWithGroup:self.currentDocument.rootGroup
																	 andLine:selectionLine];
		
		//Tell the rendering controller about the selection helper so it can draw the loupe and highlight objects
		self.renderingController.selectionHelper = helper;
		
		return helper.selectionLoupeLine;
	}
		
}


-(void)addedToLine:(PSDrawingLine*)line fromPoint:(CGPoint)from toPoint:(CGPoint)to inDrawingView:(id)drawingView
{
	
	if ( line == self.renderingController.selectionHelper.selectionLoupeLine )
	{
		// Give this new line segment to the selection helper to update the selected set
		
		// We want to add this line to the selectionHelper on a background
		// thread so it won't block the redrawing as much as possible
		// That requires us to bundle up the points as objects instead of structs
		// so they'll fit in a dictionary to pass to the performSelectorInBackground method
		NSDictionary* pointsDict = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSValue valueWithCGPoint:from], @"from",
									[NSValue valueWithCGPoint:to], @"to", nil];
		[self.renderingController performSelectorInBackground:@selector(addLineFromDict:) withObject:pointsDict];
	}
}


-(void)finishedDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	if ( line == self.renderingController.selectionHelper.selectionLoupeLine )
	{
		//Clean up selection state
		[PSDataModel deleteDrawingLine:self.renderingController.selectionHelper.selectionLoupeLine];
		self.renderingController.selectionHelper = nil;
	}
	else
	{
		[PSDataModel save];
	}
}


-(void)cancelledDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	//TODO: similar to finishedDrawing
	PS_FAIL(@"NOT YET IMPLEMENTED: cancelledDrawingLine:");
}




/*
 ----------------------------------------------------------------------------
 PSSRTManipulatoDelegate methods
 Called by our manipulator(s) when they are manipulated
 ----------------------------------------------------------------------------
 */


-(void)manipulator:(id)sender didUpdateBy:(CGAffineTransform)incrementalTransform toTransform:(CGAffineTransform)fullTransform
{

	
}

@end
