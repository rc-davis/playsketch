//
//  PSDrawingItem.h
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-13.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PSDrawingGroup;

@interface PSDrawingItem : NSManagedObject

@property (nonatomic, retain) PSDrawingGroup *group;
@property(nonatomic) CGPoint* points;

@end
