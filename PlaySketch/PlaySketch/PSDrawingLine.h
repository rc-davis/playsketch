//
//  PSDrawingLine.h
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-14.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PSDrawingGroup;

@interface PSDrawingLine : NSManagedObject

@property (nonatomic, retain) UNKNOWN_TYPE points;
@property (nonatomic, retain) NSData * pointsAsData;
@property (nonatomic, retain) PSDrawingGroup *group;

@end
