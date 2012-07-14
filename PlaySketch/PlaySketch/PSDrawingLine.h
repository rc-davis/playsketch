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
{

	// For performance reasons, we want to cache our points in a raw C array
	// This data is accessed on each draw loop, so we don't want any read overhead
	// Custom logic is needed in the implementation for marshalling this into 
	// self.pointsAsData for persisting into our core data storage
	CGPoint* points;
	int pointCount;
	int pointBufferCount;
	
}

@property (nonatomic, retain) NSData * pointsAsData;
@property (nonatomic, retain) PSDrawingGroup *group;

-(void)addPoint:(CGPoint)p;

@end
