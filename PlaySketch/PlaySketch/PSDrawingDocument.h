//
//  PSDrawingDocument.h
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-15.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PSDrawingGroup;

@interface PSDrawingDocument : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) PSDrawingGroup *rootGroup;

@end
