//
//  PSDrawingGroup.h
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-14.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PSDrawingGroup, PSDrawingLine;

@interface PSDrawingGroup : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * rootGroup;
@property (nonatomic, retain) UNKNOWN_TYPE currentSRTLocation;
@property (nonatomic, retain) UNKNOWN_TYPE currentSRTSpeed;
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

@end
