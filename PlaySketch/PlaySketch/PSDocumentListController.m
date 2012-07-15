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
#import <QuartzCore/QuartzCore.h>

@interface PSDocumentListController ()
@property(nonatomic,retain)NSArray* documentButtons;
@property(nonatomic,retain)NSArray* documentRoots;

-(void)generateButtons;
-(void)clearButtons;
@end

@implementation PSDocumentListController
@synthesize scrollView = _scrollView;
@synthesize documentRoots = _documentRoots;
@synthesize documentButtons = _documentButtons;


/*
	This is called after everything in the storyboard is loaded, but right
	before the view is shown on the screen.
	This is our chance to refresh the view's state before presenting it
*/
- (void)viewDidLoad
{
    [super viewDidLoad];
	[self generateButtons];
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
	self.documentRoots = [PSDataModel allDrawingDocumentRoots];
	NSMutableArray* buttons = [NSMutableArray arrayWithCapacity:self.documentRoots.count];
	
	// Set up some size variables for doing the layout of the buttons
	CGRect buttonFrame = CGRectMake(0, 0, 462, 300);
	CGFloat STEPSIZE = buttonFrame.size.width + 200;
	CGFloat centerX =  STEPSIZE/2;	

	// Give the scrollview's scrolling area the right size to hold them all...
	CGSize newContentSize = self.scrollView.contentSize;
	newContentSize.width = self.documentRoots.count*STEPSIZE;
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
		
		centerX += STEPSIZE;
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




-(IBAction)newDocument:(id)sender
{
	PSDrawingGroup* group = [PSDataModel newDocumentRoot];
	[self generateButtons];
	
	//Todo: scroll to center on the new button
}

@end
