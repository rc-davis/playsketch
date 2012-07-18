//
//  PSSelectionSet.h
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-16.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSDataModel.h"

@interface PSSelectionHelper : NSObject
@property(atomic,retain) NSSet* selectedLines; // must be atomic since adding in background
@property(nonatomic,retain) PSDrawingLine* selectionLoupeLine;

-(id)initWithGroup:(PSDrawingGroup*)rootGroup andLine:(PSDrawingLine*)line;
-(void)addLineFrom:(CGPoint)from to:(CGPoint)to;
-(void)addLineFromDict:(NSDictionary*)pointsDict;


@end
