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
