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
#import "PSAppDelegate.h"

@interface PSSceneViewController ()

@property(nonatomic,retain)NSManagedObjectContext *dataContext;

-(PSDrawingGroup*)fetchOrCreateRootGroup;
-(void)DEBUG_printContextTotalObjectCount;

@end



@implementation PSSceneViewController
@synthesize dataContext = _dataContext;
@synthesize renderingController = _renderingController;


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Fetch our Core Data context from the app delegate
	PSAppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
	self.dataContext = appDelegate.managedObjectContext;
	

	// Add the renderingview to our viewcontroller hierarchy
	[self addChildViewController:self.renderingController];
	[self.renderingController viewDidLoad];
		NSLog(@"chid added!");
}

- (void)viewDidUnload
{
    [super viewDidUnload];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(PSDrawingGroup*)fetchOrCreateRootGroup
{
	// Search the data store for a PSDrawingGroup with rootGroup == YES
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"PSDrawingGroup"];
	request.fetchLimit = 1;
	request.predicate = [NSPredicate predicateWithFormat:@"rootGroup == YES"];
	NSArray* allRootGroups = [self.dataContext executeFetchRequest:request error:nil];
	
	if( allRootGroups && allRootGroups.count > 0 )
	{
		return [allRootGroups objectAtIndex:0];
	}
	else
	{
		//Create a new root object
		PSDrawingGroup* newRoot = (PSDrawingGroup*)[NSEntityDescription 
													insertNewObjectForEntityForName:@"PSDrawingGroup" 
													inManagedObjectContext:self.dataContext];
		//Set its properties
		newRoot.rootGroup = [NSNumber numberWithBool:YES];
		newRoot.name = @"New Auto-generated Root";
		//Save
		NSError *error;
		if (![self.dataContext save:&error])
			NSLog(@"Failed to save context!: %@", [error localizedDescription]);
		
		NSLog(@"After Creating new Root Group:");
		[self DEBUG_printContextTotalObjectCount];
		
		return newRoot;
	}
}


@end
