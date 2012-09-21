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

@class PSDrawingGroup;

@interface PSDrawingLine : NSManagedObject

@property (nonatomic, retain) NSData * pointsAsData;
@property (nonatomic, retain) NSNumber* color;
@property (nonatomic, retain) PSDrawingGroup *group;
@property (nonatomic, readonly) CGPoint* points;
@property (nonatomic, readonly) int pointCount;
@property (atomic) int* selectionHitCounts;

- (void)addPoint:(CGPoint)p;
- (void)addLineTo:(CGPoint)to;
- (void)applyTransform:(CGAffineTransform)transform;

- (CGRect)boundingRect;
- (void)prepareForSelection;

@end
