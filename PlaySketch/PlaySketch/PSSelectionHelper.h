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
@property(nonatomic,retain) NSMutableSet* selectedLines;

-(id)initWithGroup:(PSDrawingGroup*)rootGroup;
-(void)addLineFrom:(CGPoint)from to:(CGPoint)to;


@end
