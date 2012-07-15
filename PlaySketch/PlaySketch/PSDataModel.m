/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSDataModel.h"
#import "PSAppDelegate.h"

// Private functions:
@interface PSDataModel ()
+(NSManagedObjectContext*)context;
@end


@implementation PSDataModel


+(NSArray*)allDrawingDocuments;
{
	// Search the data store for all PSDrawingDocuments
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"PSDrawingDocument"];
	NSArray* allDocuments = [[PSDataModel context] executeFetchRequest:request error:nil];	
	NSLog(@"Found %d Documents", allDocuments.count);
	return allDocuments;
}


+(PSDrawingDocument*)newDrawingDocumentWithName:(NSString*)name
{
	//Create a new root object
	PSDrawingDocument* newDocument = (PSDrawingDocument*)[NSEntityDescription 
												insertNewObjectForEntityForName:@"PSDrawingDocument" 
												inManagedObjectContext:[PSDataModel context]];
	
	//Set its properties
	newDocument.name = name;
	
	//Save it
	NSError *error;
	if (![[ PSDataModel context] save:&error])
		NSLog(@"Failed to save context!: %@", [error localizedDescription]);
	
	return newDocument;
}



-(IBAction)eraseAll:(id)sender
{
	//TODO: DELETE
	PS_NOT_YET_IMPLEMENTED();
	
}



/*
	Debug helper methods!
	To help us with development
*/
 
+(void)DEBUG_printTotalObjectCount
 {
	 NSFetchRequest* requestGroup = [NSFetchRequest fetchRequestWithEntityName:@"PSDrawingGroup"];
	 NSArray* allGroups = [[PSDataModel context] executeFetchRequest:requestGroup error:nil];
 
	 NSFetchRequest* requestLines = [NSFetchRequest fetchRequestWithEntityName:@"PSDrawingLine"];
	 NSArray* allLines = [[PSDataModel context] executeFetchRequest:requestLines error:nil];
 
	 NSLog(@"--- Context contains a total of:\nGroups:%d\nLines:%d", allGroups.count, allLines.count);
 }
 
+(void)DEBUG_generateTestShapesIntoGroup:(PSDrawingGroup*)rootGroup
 {
 
		//Add a square to the root group centered on 50,50
	 PSDrawingLine* rootSquare = (PSDrawingLine*)[NSEntityDescription 
	 insertNewObjectForEntityForName:@"PSDrawingLine" 
	 inManagedObjectContext:[PSDataModel context]];
	 rootSquare.group = rootGroup;
	 [rootSquare addLineFrom:CGPointZero to:CGPointMake(0,0)];
	 [rootSquare addLineFrom:CGPointZero to:CGPointMake(100,0)];
	 [rootSquare addLineFrom:CGPointZero to:CGPointMake(100,100)];
	 [rootSquare addLineFrom:CGPointZero to:CGPointMake(0,100)];
	 [rootSquare addLineFrom:CGPointZero to:CGPointMake(0,0)];
	 
	 
	 //Create a subgroup
	 PSDrawingGroup* subgroup1 = (PSDrawingGroup*)[NSEntityDescription 
	 insertNewObjectForEntityForName:@"PSDrawingGroup" 
	 inManagedObjectContext:[PSDataModel context]];
	 subgroup1.parent = rootGroup;
	 
	 
	 //Add a triangle to subgroup, centered around 100,100
	 PSDrawingLine* subgroupTriangle = (PSDrawingLine*)[NSEntityDescription 
	 insertNewObjectForEntityForName:@"PSDrawingLine" 
	 inManagedObjectContext:[PSDataModel context]];
	 subgroupTriangle.group = subgroup1;
	 [subgroupTriangle addLineFrom:CGPointZero to:CGPointMake(100, 100 + 50)];
	 [subgroupTriangle addLineFrom:CGPointZero to:CGPointMake(100 - 43.3012702, 100 - 25)];
	 [subgroupTriangle addLineFrom:CGPointZero to:CGPointMake(100 + 43.3012702, 100 - 25)];
	 [subgroupTriangle addLineFrom:CGPointZero to:CGPointMake(100, 100 + 50)];
	 
	 
	 //this should look like ferris-wheel style nested motion, moving to the right and growing
	 [rootGroup setCurrentSRTRate:SRTRateMake( 50, 0, 0.2, 2 )];
	 [rootGroup setCurrentSRTPosition:SRTPositionMake(0, 300, 1, 0, 50, 50)];
	 [subgroup1 setCurrentSRTRate:SRTRateMake( 0, 0, 0, -2 )];
	 [subgroup1 setCurrentSRTPosition:SRTPositionMake(100, 100, 1, 0, 100, 100)];
 
 }


+(NSManagedObjectContext*)context
{
	static NSManagedObjectContext* __context; // A static singleton for the class
	
	if(__context == nil)
	{
		PSAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
		__context = [appDelegate managedObjectContext];
	}
	return __context;
}

@end
