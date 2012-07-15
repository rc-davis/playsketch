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

@interface PSDocumentListController ()

@end

@implementation PSDocumentListController
@synthesize scrollView = _scrollView;


/*
	This is called after everything in the storyboard is loaded, but right
	before the view is shown on the screen.
	This is our chance to refresh the view's state before presenting it
*/
- (void)viewDidLoad
{
    [super viewDidLoad];

	// Fetch a list of all the documents
	NSArray* allDocuments = [PSDataModel allDrawingDocumentRoots];
	
	// create a view for each document and add to the scroll view
	CGRect buttonFrame = CGRectMake(0, 0, 200, 400);
	CGFloat STEPSIZE = buttonFrame.size.width + 200;
	CGFloat centerX =  STEPSIZE/2;
	
	NSLog(@"SCROLLVIEW HEIGHT: %lf", self.scrollView.bounds.size.height);
	
	CGSize newContentSize = self.scrollView.contentSize;
	newContentSize.width = allDocuments.count*STEPSIZE;
	self.scrollView.contentSize = newContentSize;
	
	for(PSDrawingGroup* docRoot in allDocuments)
	{
		UIButton* docButton = [[UIButton alloc] initWithFrame:buttonFrame];
		docButton.backgroundColor = [UIColor colorWithRed:0.627 green:1.000 blue:0.653 alpha:1.000];
		docButton.center = CGPointMake(centerX, self.scrollView.bounds.size.height/2.0);
		[self.scrollView addSubview:docButton];
		centerX += STEPSIZE;
	}
}


/*
	This is called right after the view has left the screen. 
	It gives us the opportunity to free any resources the view was using.
*/
- (void)viewDidUnload
{
	[super viewDidUnload];

	
	// Release all of our views
	// TODO
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


-(IBAction)newDocument:(id)sender
{
	PSDrawingGroup* group = [PSDataModel newDocumentRoot];
}

@end
