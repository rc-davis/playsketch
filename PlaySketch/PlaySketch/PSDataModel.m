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
+ (NSManagedObjectContext*)context;
@end


@implementation PSDataModel

+ (void)save
{
	[[PSDataModel context] save:nil];
	NSLog(@"SAVING");
}

+ (NSArray*)allDrawingDocuments;
{
	// Search the data store for all PSDrawingDocuments
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"PSDrawingDocument"];
	NSArray* allDocuments = [[PSDataModel context] executeFetchRequest:request error:nil];	
	return allDocuments;
}


+ (PSDrawingDocument*)newDrawingDocumentWithName:(NSString*)name
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


+ (PSDrawingGroup*)newDrawingGroupWithParent:(PSDrawingGroup*)parent
{
	//Create a new root object
	PSDrawingGroup* newGroup = (PSDrawingGroup*)[NSEntityDescription 
													  insertNewObjectForEntityForName:@"PSDrawingGroup" 
												 inManagedObjectContext:[PSDataModel context]];
	newGroup.parent = parent;
	return newGroup;
}


+ (PSDrawingLine*)newLineInGroup:(PSDrawingGroup*)group withWeight:(int)weight
{
	PSDrawingLine* newLine = (PSDrawingLine*)[NSEntityDescription 
											  insertNewObjectForEntityForName:@"PSDrawingLine" inManagedObjectContext:[PSDataModel context]];
	newLine.group = group;
	newLine.penWeight = weight;
	return newLine;
}


+ (PSDrawingLine*)newTemporaryLineWithWeight:(int)weight andColor:(UInt64)color
{
	// Note: Something funny is happening here!
	// When we create an object normally, it is created with a specific "managedObjectContext",
	// which is basically like a specific CoreData database.
	// This gets you a bunch of default functionality, like being persisted automatically,
	// and getting added to the undo/redo stack
	// We don't always want that, like when the line is still tentative, or not not intended to be
	// permanent, like the selection lasso.
	// By creating the object with a nil managedObjectContext we avoid all of that.
	// There is an important catch:
	// Since it doesn't belong to the same database, it cannot have relationships
	// (parent/child/etc) with other objects that do have a managedObjectContext
	// Before setting any of those relationships, call makeTemporaryLinePermanent:
	// to insert it into the database
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"PSDrawingLine"
											  inManagedObjectContext:[PSDataModel context]];
	
	PSDrawingLine* newLine = (PSDrawingLine*)[[NSManagedObject alloc] initWithEntity:entity
													  insertIntoManagedObjectContext:nil];
	newLine.penWeight = weight;
	newLine.color = [NSNumber numberWithUnsignedLongLong:color];
	return newLine;
}


+ (void)deleteDrawingDocument:(PSDrawingDocument*)doc
{
	
	[[PSDataModel context] deleteObject:doc];
	[PSDataModel save];

}


+ (void)deleteDrawingGroup:(PSDrawingGroup*)group
{
	[[PSDataModel context] deleteObject:group];
}


+ (void)deleteDrawingLine:(PSDrawingLine*)line
{

	[[PSDataModel context] deleteObject:line];
}


+ (BOOL)canUndo
{
	return [[PSDataModel context].undoManager canUndo];
}

+ (BOOL)canRedo
{
	return [[PSDataModel context].undoManager canRedo];
}

+ (void)undo
{
	[[PSDataModel context] undo];
}

+ (void)redo
{
	[[PSDataModel context] redo];
}

+ (void)clearUndoStack
{
	[[PSDataModel context].undoManager removeAllActions];
}

+ (void)beginUndoGroup
{
	[[PSDataModel context].undoManager beginUndoGrouping];
}

+ (void)endUndoGroup
{
	[[PSDataModel context].undoManager endUndoGrouping];
}

+ (void)makeTemporaryLinePermanent:(PSDrawingLine*)line
{
	[[PSDataModel context] insertObject:line];
}

+ (NSManagedObjectContext*)context
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
