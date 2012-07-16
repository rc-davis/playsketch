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
@property(nonatomic,retain)PSSelectionHelper* selectionHelper;
@end



@implementation PSSceneViewController
@synthesize renderingController = _renderingController;
@synthesize drawingTouchView = _drawingTouchView;
@synthesize currentDocument = _currentDocument;
@synthesize isSelecting = _isSelecting;
@synthesize selectionHelper = _selectionHelper;



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
		//Start a new selection set helper
		self.selectionHelper = [[PSSelectionHelper alloc] initWithGroup:self.currentDocument.rootGroup];
		
		//Tell the rendering controller to draw the selection loupe and highlight objects
		self.renderingController.selectionLoupeLine = [PSDataModel newLineInGroup:nil];
		self.renderingController.selectedLines = self.selectionHelper.selectedLines;
		
		return self.renderingController.selectionLoupeLine;
	}
		
}

-(void)addedToLine:(PSDrawingLine*)line fromPoint:(CGPoint)from toPoint:(CGPoint)to inDrawingView:(id)drawingView
{
	
	if ( line == self.renderingController.selectionLoupeLine )
		[self.selectionHelper addLineFrom:from to:to];
	
}

-(void)finishedDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	if ( line == self.renderingController.selectionLoupeLine )
	{
		//Clean up selection state
		[PSDataModel deleteDrawingLine:self.renderingController.selectionLoupeLine];
		self.renderingController.selectionLoupeLine = nil;
		
		self.selectionHelper = nil;
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
