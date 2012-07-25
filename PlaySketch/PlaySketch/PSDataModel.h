/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

/*

	This should be the only entry point to the data store.
	All data retrieval and manipulation should happen through this file,
	or through objects returned by this file.
 
	TODO: The goal is to eventually rip this out into its own framework for
	use in Mac & iOS.

 */


#import <Foundation/Foundation.h>
#import "PSDrawingDocument.h"
#import "PSDrawingGroup.h"
#import "PSDrawingLine.h"

@interface PSDataModel : NSObject


+(void)save;
+(NSArray*)allDrawingDocuments;
+(PSDrawingDocument*)newDrawingDocumentWithName:(NSString*)name;
+(PSDrawingGroup*)newDrawingGroupWithParent:(PSDrawingGroup*)parent;
+(PSDrawingLine*)newLineInGroup:(PSDrawingGroup*)group;
+(PSDrawingGroup*)newChildOfGroup:(PSDrawingGroup*)parentGroup withLines:(NSSet*)lines;
+(PSDrawingGroup*)mergeGroup:(PSDrawingGroup*)group intoParentAtTime:(float)time;
+(void)deleteDrawingDocument:(PSDrawingDocument*)doc;
+(void)deleteDrawingGroup:(PSDrawingGroup*)group;
+(void)deleteDrawingLine:(PSDrawingLine*)line;

+(void)DEBUG_printTotalObjectCount;
+(void)DEBUG_generateTestShapesIntoGroup:(PSDrawingGroup*)rootGroup;
+(void)DEBUG_generateRandomLittleLinesIntoGroup:(PSDrawingGroup*)rootGroup lineCount:(int)lineCount;

@end
