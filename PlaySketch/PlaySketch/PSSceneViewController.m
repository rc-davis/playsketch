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
@property(nonatomic,retain) PSSelectionHelper* selectionHelper;
@property(nonatomic, retain) UIColor* currentColor; // the color the pen right now
@end



@implementation PSSceneViewController
@synthesize renderingController = _renderingController;
@synthesize drawingTouchView = _drawingTouchView;
@synthesize startDrawingButton = _startDrawingButton;
@synthesize startSelectingButton = _startSelectingButton;
@synthesize currentDocument = _currentDocument;
@synthesize selectedSetManipulator = _manipulator;
@synthesize isSelecting = _isSelecting;
@synthesize selectionHelper = _selectionHelper;
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
	self.currentColor = [UIColor colorWithWhite:0.200 alpha:1.000];
	
	
	//Create a manipulator and add it to our rendering view hidden
	self.selectedSetManipulator = [[PSSRTManipulator alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	[self.renderingController.view addSubview:self.selectedSetManipulator];
	self.selectedSetManipulator.hidden = YES;
	self.selectedSetManipulator.delegate = self;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
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
		self.selectedSetManipulator.hidden = YES;
		
	}
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
	UIColor* color = [sender backgroundColor];
	self.currentColor = color;
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
		self.selectedSetManipulator.hidden = YES;
	}
	
	if (! self.isSelecting )
	{
		PSDrawingLine* line = [PSDataModel newLineInGroup:self.currentDocument.rootGroup];
		line.color = self.currentColor;
		return line;
	}
	else
	{
		// Create a line to draw
		PSDrawingLine* selectionLine = [PSDataModel newLineInGroup:nil];

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
			self.selectedSetManipulator.hidden = NO;
			CGRect linesFrame = [PSDrawingLine calculateFrameForLines:self.selectionHelper.selectedLines];
			
//			for (PSDrawingLine* line in self.selectionHelper.selectedLines)
//				[line applyIncrementalTransform:CGAffineTransformMakeTranslation(linesFrame.origin.x, linesFrame.origin.y)];
			
			self.selectedSetManipulator.frame = CGRectMake(-linesFrame.size.width/2, 
														   -linesFrame.size.height/2,
														   linesFrame.size.width,
														   linesFrame.size.height);
			CGPoint middle = CGPointMake(linesFrame.origin.x + linesFrame.size.width/2, 
										 linesFrame.origin.y + linesFrame.size.height/2);
			self.selectedSetManipulator.transform = CGAffineTransformMakeTranslation(middle.x, middle.y);
																					 
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


-(void)manipulator:(id)sender didUpdateBy:(CGAffineTransform)incrementalTransform toTransform:(CGAffineTransform)fullTransform
{
	
	for (PSDrawingLine* line in self.selectionHelper.selectedLines)
		[line applyIncrementalTransform:incrementalTransform];
}

@end
