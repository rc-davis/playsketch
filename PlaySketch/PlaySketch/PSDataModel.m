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
#import "PSHelpers.h"

// Private functions:
@interface PSDataModel ()
+(NSManagedObjectContext*)context;
@end


@implementation PSDataModel

+(void)save
{
	[[PSDataModel context] save:nil];
	NSLog(@"SAVING");
}

+(NSArray*)allDrawingDocuments;
{
	// Search the data store for all PSDrawingDocuments
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"PSDrawingDocument"];
	NSArray* allDocuments = [[PSDataModel context] executeFetchRequest:request error:nil];	
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

	//Create a root group for it
	newDocument.rootGroup = [PSDataModel newDrawingGroupWithParent:nil];
	
	[PSDataModel save];
	
	return newDocument;
}


+(PSDrawingGroup*)newDrawingGroupWithParent:(PSDrawingGroup*)parent
{
	//Create a new root object
	PSDrawingGroup* newGroup = (PSDrawingGroup*)[NSEntityDescription 
													  insertNewObjectForEntityForName:@"PSDrawingGroup" 
												 inManagedObjectContext:[PSDataModel context]];
	newGroup.parent = parent;
	return newGroup;
}


+(PSDrawingLine*)newLineInGroup:(PSDrawingGroup*)group withWeight:(int)weight
{
	PSDrawingLine* newLine = (PSDrawingLine*)[NSEntityDescription 
											  insertNewObjectForEntityForName:@"PSDrawingLine" inManagedObjectContext:[PSDataModel context]];
	newLine.group = group;
	newLine.penWeight = weight;
	return newLine;
}


+(void)deleteDrawingDocument:(PSDrawingDocument*)doc
{
	
	[[PSDataModel context] deleteObject:doc];
	[PSDataModel save];

}


+(void)deleteDrawingGroup:(PSDrawingGroup*)group
{

	[[PSDataModel context] deleteObject:group];
	[PSDataModel save];

}


+(void)deleteDrawingLine:(PSDrawingLine*)line
{

	[[PSDataModel context] deleteObject:line];
	[PSDataModel save];
	
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
 
+(void)DEBUG_generateTestShapesIntoGroup:(PSDrawingGroup*)parentGroup
 {
	 PSDrawingGroup* rootGroup = [PSDataModel newDrawingGroupWithParent:parentGroup];
	 
		//Add a square to the root group centered on 50,50
	 PSDrawingLine* rootSquare = (PSDrawingLine*)[NSEntityDescription 
	 insertNewObjectForEntityForName:@"PSDrawingLine" 
	 inManagedObjectContext:[PSDataModel context]];
	 rootSquare.group = rootGroup;
	 [rootSquare addLineTo:CGPointMake(0,0)];
	 [rootSquare addLineTo:CGPointMake(100,0)];
	 [rootSquare addLineTo:CGPointMake(100,100)];
	 [rootSquare addLineTo:CGPointMake(0,100)];
	 [rootSquare addLineTo:CGPointMake(0,0)];
	 
	 
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
	 [subgroupTriangle addLineTo:CGPointMake(100, 100 + 50)];
	 [subgroupTriangle addLineTo:CGPointMake(100 - 43.3012702, 100 - 25)];
	 [subgroupTriangle addLineTo:CGPointMake(100 + 43.3012702, 100 - 25)];
	 [subgroupTriangle addLineTo:CGPointMake(100, 100 + 50)];
	 
	 
	 //this should look like ferris-wheel style nested motion, moving to the right and growing
	 [rootGroup addPosition:SRTPositionMake(0, 0, 300, 1, 0, 50, 50, YES) withInterpolation:NO];
	 [rootGroup addPosition:SRTPositionMake(5, 500, 300, 2, M_PI*4, 50, 50, YES) withInterpolation:NO];
	 [subgroup1 addPosition:SRTPositionMake(0, 100, 100, 1, 0, 100, 100, YES) withInterpolation:NO];
	 [subgroup1 addPosition:SRTPositionMake(5, 100, 100, 1, M_PI*-4, 100, 100, YES) withInterpolation:NO];
 
 }

+(void)DEBUG_generateRandomLittleLinesIntoGroup:(PSDrawingGroup*)rootGroup lineCount:(int)lineCount
{
	int POINT_COUNT = 1000;
	CGSize viewSize = CGSizeMake(400, 300);
	srand(100);
	
	for (int i = 0; i < lineCount; i ++)
	{
		CGPoint start = CGPointMake(rand()%(int)viewSize.width, rand()%(int)viewSize.height);
		PSDrawingLine* line = [PSDataModel newLineInGroup:rootGroup withWeight:4];
		for(int j = 0; j < POINT_COUNT; j++)
		{
			CGPoint next = CGPointMake(start.x + rand()%4, start.y + rand()%4 );
			[line addLineTo:next];
			start = next;
		}
		int64_t color = [PSHelpers colorToInt64:[UIColor colorWithRed:(rand()%10)/10.0
																green:(rand()%10)/10.0
																 blue:(rand()%10)/10.0
																alpha:1.0]];
		line.color = [NSNumber  numberWithLongLong:color];
	}
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
