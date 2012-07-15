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


+(NSArray*)allDrawingDocumentRoots
{
	// Search the data store for all PSDrawingGroup with rootGroup == YES
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"PSDrawingGroup"];
	request.predicate = [NSPredicate predicateWithFormat:@"rootGroup == YES"];
	NSArray* allRootGroups = [[PSDataModel context] executeFetchRequest:request error:nil];	
	NSLog(@"Found %d Documents", allRootGroups.count);
	return allRootGroups;
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
