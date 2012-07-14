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
	

	// Bind our rendering Controller to the root group we want to use
	self.renderingController.rootGroup = [self fetchOrCreateRootGroup];

}

- (void)viewDidUnload
{
    [super viewDidUnload];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


-(IBAction)eraseAll:(id)sender
{
	NSLog(@"Before Erasing:");
	[self DEBUG_printContextTotalObjectCount];
	

	// 1. Erase everything descendent from our current root controller
	PSDrawingGroup* rootGroup = self.renderingController.rootGroup;
	self.renderingController.rootGroup = nil;
	[self.dataContext deleteObject:rootGroup];
	

	NSLog(@"After Erasing");
	[self DEBUG_printContextTotalObjectCount];

	
	// 2. Fetch a new one
	self.renderingController.rootGroup = [self fetchOrCreateRootGroup];
	
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



//TODO: temporary
-(void)DEBUG_printContextTotalObjectCount
{
	NSFetchRequest* requestGroup = [NSFetchRequest fetchRequestWithEntityName:@"PSDrawingGroup"];
	NSArray* allGroups = [self.dataContext executeFetchRequest:requestGroup error:nil];

	NSFetchRequest* requestLines = [NSFetchRequest fetchRequestWithEntityName:@"PSDrawingLine"];
	NSArray* allLines = [self.dataContext executeFetchRequest:requestLines error:nil];

	NSLog(@"--- Context contains a total of:\nGroups:%d\nLines:%d", allGroups.count, allLines.count);
}

-(IBAction)DEBUG_generateTestShapes:(id)sender
{
	PSDrawingGroup* rootGroup = self.renderingController.rootGroup;
	
	//Add a square to the root group centered on 50,50
	PSDrawingLine* rootSquare = (PSDrawingLine*)[NSEntityDescription 
											insertNewObjectForEntityForName:@"PSDrawingLine" 
											inManagedObjectContext:self.dataContext];
	rootSquare.group = rootGroup;
	[rootSquare addLineFrom:CGPointZero to:CGPointMake(0,0)];
	[rootSquare addLineFrom:CGPointZero to:CGPointMake(100,0)];
	[rootSquare addLineFrom:CGPointZero to:CGPointMake(100,100)];
	[rootSquare addLineFrom:CGPointZero to:CGPointMake(0,100)];
	[rootSquare addLineFrom:CGPointZero to:CGPointMake(0,0)];

	
	
}

@end
