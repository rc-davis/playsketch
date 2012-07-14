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

@class PSDrawingGroup, PSDrawingLine;

@interface PSDrawingGroup : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * rootGroup;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) PSDrawingLine *parent;
@property (nonatomic, retain) NSSet *drawingLines;
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

@end
