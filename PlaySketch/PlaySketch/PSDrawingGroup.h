/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PSPrimitiveDataStructs.h"

@class PSDrawingGroup, PSDrawingLine;

@interface PSDrawingGroup : NSManagedObject
{
	// These are transient properties which are not stored in the model
	SRTPosition currentSRTPosition;
	SRTRate currentSRTRate;
	GLKMatrix4 currentModelViewMatrix;

}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * rootGroup;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) NSSet *drawingLines;
@property (nonatomic, retain) PSDrawingGroup *parent;
@end

@interface PSDrawingGroup (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(PSDrawingGroup *)value;
- (void)removeChildrenObject:(PSDrawingGroup *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

- (void)addDrawingLinesObject:(PSDrawingLine *)value;
- (void)removeDrawingLinesObject:(PSDrawingLine *)value;
- (void)addDrawingLines:(NSSet *)values;
- (void)removeDrawingLines:(NSSet *)values;

- (CGRect)calculateFrame;

//TODO TEMP
-(void)setCurrentSRTRate:(SRTRate)r;
-(void)setCurrentSRTPosition:(SRTPosition)p;

@end
