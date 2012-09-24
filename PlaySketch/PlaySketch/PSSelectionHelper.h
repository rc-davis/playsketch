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
@property(nonatomic,retain) PSDrawingLine* selectionLoupeLine;
@property(readonly) int selectedGroupCount;

+ (PSSelectionHelper*)selectionWithLine:(PSDrawingLine*)line inRootGroup:(PSDrawingGroup*)rootGroup;
+ (PSSelectionHelper*)selectionForTap:(CGPoint)tapPoint inRootGroup:(PSDrawingGroup*)rootGroup;
- (void)addLineFrom:(CGPoint)from to:(CGPoint)to;
- (void)addLineFromDict:(NSDictionary*)pointsDict;
- (BOOL)singleLeafOnlySelected;

@end
