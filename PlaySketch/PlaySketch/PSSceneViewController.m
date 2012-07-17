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

@interface PSSceneViewController ()
@property(nonatomic)BOOL isSelecting; // If we are selecting instead of drawing
@end



@implementation PSSceneViewController
@synthesize renderingController = _renderingController;
@synthesize drawingTouchView = _drawingTouchView;
@synthesize currentDocument = _currentDocument;
@synthesize isSelecting = _isSelecting;



-(void)setCurrentDocument:(PSDrawingDocument *)currentDocument
{
	_currentDocument = currentDocument;
	self.renderingController.rootGroup = currentDocument.rootGroup;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Add the renderingview to our viewcontroller hierarchy
	[self addChildViewController:self.renderingController];
	[self.renderingController viewDidLoad];
	
}

- (void)viewDidUnload
{
    [super viewDidUnload];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(IBAction)play:(id)sender
{

}


-(IBAction)dismissSceneView:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}


/*
	Begins selection mode for selecting lines to put into a character
	If already in selection mode, dismisses
*/
-(IBAction)toggleCharacterCreation:(id)sender
{
	self.isSelecting = !self.isSelecting;

	//TODO: other clean up?
}




/*
	PSDrawingEventsViewDrawingDelegate methods
	Decides whether to add a new drawing line or a new selection line
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

-(void)backgroundAddLine:(NSDictionary*)points
{
	CGPoint from = [[points objectForKey:@"from"] CGPointValue];
	CGPoint to = [[points objectForKey:@"to"] CGPointValue];
	[self.renderingController.selectionHelper addLineFrom:from to:to];
}

-(void)addedToLine:(PSDrawingLine*)line fromPoint:(CGPoint)from toPoint:(CGPoint)to inDrawingView:(id)drawingView
{
	
	if ( line == self.renderingController.selectionHelper.selectionLoupeLine )
	{
		// We want to add this line to the selectionHelper on a background
		// thread so it won't block the redrawing as much as possible
		// That requires us to bundle up the points as objects instead of structs
		// so they'll fit in a dictionary to pass to the performSelectorInBackground function
		NSValue* fromV = [NSValue valueWithCGPoint:from];
		NSValue* toV = [NSValue valueWithCGPoint:to];
		NSDictionary* pointsDict = [NSDictionary dictionaryWithObjectsAndKeys:
									fromV, @"from",
									toV, @"to", nil];
		[self performSelectorInBackground:@selector(backgroundAddLine:) withObject:pointsDict];
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
	PS_NOT_YET_IMPLEMENTED();
}

@end
