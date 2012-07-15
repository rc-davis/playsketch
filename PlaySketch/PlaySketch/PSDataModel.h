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
+(void)deleteDrawingDocument:(PSDrawingDocument*)doc;

+(void)DEBUG_printTotalObjectCount;
+(void)DEBUG_generateTestShapesIntoGroup:(PSDrawingGroup*)rootGroup;


@end
