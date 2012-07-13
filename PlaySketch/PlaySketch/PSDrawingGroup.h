//
//  PSDrawingGroup.h
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-13.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PSDrawingGroup, PSDrawingItem;

@interface PSDrawingGroup : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * rootGroup;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) PSDrawingItem *parent;
@property (nonatomic, retain) NSSet *drawingItems;
@end

@interface PSDrawingGroup (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(PSDrawingGroup *)value;
- (void)removeChildrenObject:(PSDrawingGroup *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

- (void)addDrawingItemsObject:(PSDrawingItem *)value;
- (void)removeDrawingItemsObject:(PSDrawingItem *)value;
- (void)addDrawingItems:(NSSet *)values;
- (void)removeDrawingItems:(NSSet *)values;

@end
