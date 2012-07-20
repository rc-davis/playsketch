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
#import "PSDataModel.h"

@interface PSSelectionHelper : NSObject
@property(atomic,retain) NSSet* selectedLines; // must be atomic since adding in background
@property(nonatomic,retain) PSDrawingLine* selectionLoupeLine;

-(id)initWithGroup:(PSDrawingGroup*)rootGroup andLine:(PSDrawingLine*)line;
-(void)addLineFrom:(CGPoint)from to:(CGPoint)to;
-(void)addLineFromDict:(NSDictionary*)pointsDict;


@end
