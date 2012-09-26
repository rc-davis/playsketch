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
@property(readonly) int selectedGroupCount;

+ (void)setRootGroup:(PSDrawingGroup*)group;
+ (void)resetSelection;
+ (BOOL)findSelectionForTap:(CGPoint)tapPoint;
+ (void)addSelectionLineFrom:(CGPoint)from to:(CGPoint)to;
+ (void)addSelectionLineFromDict:(NSDictionary*)pointsDict;
+ (void)finishLassoSelection;
+ (BOOL)isSingleLeafOnlySelected;
+ (int)selectedGroupCount;
+ (void)manuallySetSelectedGroup:(PSDrawingGroup*)g;
+ (PSDrawingGroup*)leafGroup;

@end
