/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSDocumentListController.h"
#import "PSDataModel.h"
#import "PSSceneViewController.h"
#import <QuartzCore/QuartzCore.h>

#define DOC_BUTTON_STEP_SIZE 650.0 // The pixel-distance between two buttons
#define ALLOWABLE_SELECTION_OFFSET 200 // The distance away from the center of a button that is still considered selected 


@interface PSDocumentListController ()
@property(nonatomic,retain)NSArray* documentButtons;
@property(nonatomic,retain)NSArray* documentRoots;

-(void)generateButtons;
-(void)clearButtons;
-(PSDrawingDocument*)selectedDocument:(CGFloat*)outPercentFromCentered;
-(void)refreshButtonAppearance;
@end

@implementation PSDocumentListController
@synthesize scrollView = _scrollView;
@synthesize documentRoots = _documentRoots;
@synthesize documentButtons = _documentButtons;
@synthesize deleteButton = _deleteButton;
@synthesize documentNameButton = _documentNameButton;


/*
	This is called after everything in the storyboard is loaded, but right
	before the view is shown on the screen.
	This is our chance to refresh the view's state before presenting it
*/
- (void)viewDidLoad
{
    [super viewDidLoad];
	[self generateButtons];
	self.scrollView.delegate = self; //So we can respond to the scroll events
	[self refreshButtonAppearance];
}


/*
	This is called right after the view has left the screen. 
	It gives us the opportunity to free any resources the view was using.
*/
- (void)viewDidUnload
{
	[super viewDidUnload];
	[self clearButtons];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


-(void)generateButtons
{
	if(self.documentButtons != nil)
		[self clearButtons];
	
	
	// Fetch a list of all the documents
	self.documentRoots = [PSDataModel allDrawingDocuments];
	NSMutableArray* buttons = [NSMutableArray arrayWithCapacity:self.documentRoots.count];
	
	// Set up some size variables for doing the layout of the buttons
	CGRect buttonFrame = CGRectMake(0, 0, 462, 300);
	CGFloat centerX =  self.scrollView.frame.size.width/2.0;

	// Give the scrollview's scrolling area the right size to hold them all
	// This means DOC_BUTTON_STEP_SIZE for each document + padding at the start and end to be able to center
	CGSize newContentSize = self.scrollView.contentSize;
	newContentSize.width = self.documentRoots.count*DOC_BUTTON_STEP_SIZE +
							2 * (self.scrollView.frame.size.width/2.0 - DOC_BUTTON_STEP_SIZE/2.0);
	self.scrollView.contentSize = newContentSize;

	// Create a button for each document and add to the scroll view
	
	for(PSDrawingGroup* docRoot in self.documentRoots)
	{
		UIButton* docButton = [[UIButton alloc] initWithFrame:buttonFrame];
		docButton.backgroundColor = [UIColor colorWithRed:1.000 green:0.977 blue:0.842 alpha:1.000];
		docButton.center = CGPointMake(centerX, self.scrollView.bounds.size.height/2.0);
		[self.scrollView addSubview:docButton];
		[buttons addObject:docButton];

		// Add a drop shadow just because we can (take that!)
		docButton.layer.shadowColor = [UIColor blackColor].CGColor;
		docButton.layer.shadowOffset = CGSizeMake(0, 10);
		docButton.layer.shadowRadius = 10.0;
		docButton.layer.shadowOpacity = 0.5;
		
		//Hook up the button to call viewDocument:
		[docButton addTarget:self action:@selector(viewDocument:) forControlEvents:UIControlEventTouchUpInside];
		
		centerX += DOC_BUTTON_STEP_SIZE;
	}

	self.documentButtons = buttons;
}


-(void)clearButtons
{
	for(UIButton* button in self.documentButtons)
	{
		[button removeFromSuperview];
	}
	self.documentButtons = nil;
	self.documentRoots = nil;
	self.scrollView.contentSize = self.scrollView.frame.size;
	
}


/*
	We will consider the document nearest to being centered in the view to be "selected", 
	but only if it falls within ALLOWABLE_SELECTION_OFFSET of being perfectly centered.
	outPercentFromCentered is an optional argument to return how close we are to centered.
	1.0 means perfectly centred, 0.0 means off by ALLOWABLE_SELECTION_OFFSET
*/
-(PSDrawingDocument*)selectedDocument:(CGFloat*)outPercentFromCentered
{
	// Get the document that is nearest the center of the scrollview
	int currentIndex = round(self.scrollView.contentOffset.x/DOC_BUTTON_STEP_SIZE);
	currentIndex = MAX(currentIndex, 0);
	currentIndex = MIN(currentIndex, self.documentButtons.count - 1);
	
	//Calculate the percentFromCenetered
	CGFloat idealOffsetX = currentIndex * DOC_BUTTON_STEP_SIZE;
	CGFloat percentFromCentered = 1 - fabs(idealOffsetX - self.scrollView.contentOffset.x)/
									ALLOWABLE_SELECTION_OFFSET;
	if ( outPercentFromCentered )
		*outPercentFromCentered = MAX( 0, percentFromCentered );
	
	// Return the document if we are close enough
	if ( currentIndex < self.documentRoots.count && percentFromCentered > 0 )
		return [self.documentRoots objectAtIndex:currentIndex];
	else
		return nil;
}


-(IBAction)newDocument:(id)sender
{
	[PSDataModel newDrawingDocumentWithName:@"Untitled Animation"];

	CGPoint offsetBeforeAddingButton = self.scrollView.contentOffset;
	[self generateButtons];

	//Animate motion from the offset the scrollview WAS at to center on the new document

	self.scrollView.contentOffset = offsetBeforeAddingButton;
	[self.scrollView setContentOffset:
	 CGPointMake((self.documentRoots.count - 1)*DOC_BUTTON_STEP_SIZE,
				 offsetBeforeAddingButton.y) animated:YES];

	[self refreshButtonAppearance];
	
}


-(IBAction)deleteDocument:(id)sender
{
	PSDrawingDocument* docToDelete = [self selectedDocument:nil];
	if ( docToDelete )
	{
		//Delete it
		CGPoint offsetBeforeDeleting = self.scrollView.contentOffset;
		[PSDataModel deleteDrawingDocument:docToDelete];
		
		//Reload our data
		[self generateButtons];
		
		// TODO: animate the delete better
		
		// Trigger an update of our labels
		self.scrollView.contentOffset = offsetBeforeDeleting;
		[self scrollViewDidEndDecelerating:self.scrollView];
		[self refreshButtonAppearance];
		
	}
}


/*
	Show the document that corresponds to senderButton
	Do this by looking up the document that corresponds to the button clicked,
	then triggering the "GoToSceneViewController segue in the storyboard
*/
-(void)viewDocument:(id)senderButton
{
	// Find the index of the document that corresponds to this button
	int index = [self.documentButtons indexOfObject:senderButton];
	
	if ( index >= 0 && index < self.documentRoots.count)
	{
		// Call the segue from the storyboard
		PSDrawingDocument* document = [self.documentRoots objectAtIndex:index];
		[self performSegueWithIdentifier:@"GoToSceneViewController" sender:document];

		[self refreshButtonAppearance];
	}
}


/*
	Called by the button on the document name, to start renaming the selected document
*/
-(IBAction)startRenameDocument:(id)sender
{
	UIAlertView *alertView = [[UIAlertView alloc] 
							  initWithTitle:@"Rename Animation"
							  message:@"Enter a new name"
							  delegate:self
							  cancelButtonTitle:@"Cancel" 
							  otherButtonTitles:@"OK", nil];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	[alertView show];
}


/*
	UIAlertView delegate method
	This is called when an alertview is dismissed by the user.
	The only alertview that is being used here is for renaming a document
*/
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ( buttonIndex > 0 )
	{
		NSString* newName = [alertView textFieldAtIndex:0].text;
		PSDrawingDocument* document = [self selectedDocument:nil];
		
		if (newName && newName.length > 0 && document )
		{
			document.name = newName;
			[PSDataModel save];
			[self refreshButtonAppearance];
		}
	}
}


/*
	This is called automatically each time we segue away from this view
	We can tell which segue triggered this call by looking at [segue identifier]
*/
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

	// Check if this is the segue where we are loading up a scene
	// We are passing the document in as the sender in viewDocument:
    if ( [[segue identifier] isEqualToString:@"GoToSceneViewController"]
		&& [sender class] == [PSDrawingDocument class] )
    {
		//Set the root scene view controller from the supplied document
		PSSceneViewController *vc = [segue destinationViewController];
		vc.currentDocument = (PSDrawingDocument*)sender;
    }
}



/*
	Scrollview delegate methods
	Implementing these let this controller respond to changes in the scrollview,
	to keep us centred on a button
*/
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
	// Find the button that is nearest to the offset the scrollview is planning on stopping at
	int requestedIndex = round((*targetContentOffset).x/DOC_BUTTON_STEP_SIZE);
	
	// Validate/sanity-check it
	requestedIndex = MAX(requestedIndex, 0);
	requestedIndex = MIN(requestedIndex, self.documentButtons.count - 1);
	
	//Update the targetContentOffset we've been given to adjust it
	(*targetContentOffset).x = requestedIndex * DOC_BUTTON_STEP_SIZE + 0.5;
}


/*
	The above delegate callback (scrollViewWillEndDragging) SHOULD be all we 
	need to make sure our scrollview snaps to a document properly.
	It looks like there's a bug keeping it from always working, so we need to 
	duplicate the snapping functionality here. 
	See here for discussion of the bug:
	http://stackoverflow.com/questions/10880434/scrollviewwillenddraggingwithvelocitytargetcontentoffset-not-working-on-the-e
*/
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	// Find the button that is nearest to the offset the scrollview is planning on stopping at
	int requestedIndex = round(self.scrollView.contentOffset.x/DOC_BUTTON_STEP_SIZE);
	
	// Validate/sanity-check it
	requestedIndex = MAX(requestedIndex, 0);
	requestedIndex = MIN(requestedIndex, self.documentButtons.count - 1);
	
	//scroll to the right location
	[scrollView setContentOffset:CGPointMake(requestedIndex * DOC_BUTTON_STEP_SIZE, 
										   scrollView.contentOffset.y)
						animated:YES];
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self refreshButtonAppearance];
}


/*
	Update the label and delete button to fade unless the document is directly
	above them
 */
-(void)refreshButtonAppearance
{
	CGFloat percentFromCentered;
	PSDrawingDocument* currentDocument = [self selectedDocument:&percentFromCentered];
	
	if (currentDocument)
	{
		//Fade our labels according to percentFromCentered
		[self.documentNameButton setTitle:currentDocument.name forState:UIControlStateNormal];
		self.documentNameButton.alpha = percentFromCentered;
		self.documentNameButton.enabled = YES;
		self.deleteButton.alpha = percentFromCentered;
		self.deleteButton.enabled = percentFromCentered;
	}
	else
	{
		//Hide everything
		self.documentNameButton.alpha = 0.0;
		self.documentNameButton.enabled = NO;
		self.deleteButton.alpha = 0;
		self.deleteButton.enabled = NO;
	}	
}


@end
