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


- (void)viewDidLoad
{
    [super viewDidLoad];

	// Generate a list of documents
	NSArray* allDocuments = [PSDataModel allDrawingDocumentRoots];
	
	
	// make a view for each one and add to the scroll view
	
}

- (void)viewDidUnload
{
	[super viewDidUnload];

	
	// Release all of our views
	
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
