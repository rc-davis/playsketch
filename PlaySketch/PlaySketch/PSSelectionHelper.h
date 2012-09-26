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

+(PSSelectionHelper*)selectionWithRootGroup:(PSDrawingGroup*)rootGroup;
+ (PSSelectionHelper*)selectionForTap:(CGPoint)tapPoint inRootGroup:(PSDrawingGroup*)rootGroup;
- (void)addLineFrom:(CGPoint)from to:(CGPoint)to;
- (void)addLineFromDict:(NSDictionary*)pointsDict;
- (void)finishSelection;
- (BOOL)singleLeafOnlySelected;

@end
