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
#import "PSPrimitiveDataStructs.h"

#define POSITION_FPS 8.0

@class PSDrawingGroup, PSDrawingLine;

@interface PSDrawingGroup : NSManagedObject
{
	// These are transient properties which are not stored in the model
	// and are used for maintaining the animation state as we playback:
	SRTPosition currentSRTPosition;
	SRTRate currentSRTRate;
	int currentPositionIndex;
	GLKMatrix4 currentModelViewMatrix;
	BOOL _pausedTranslation;
	BOOL _pausedScale;
	BOOL _pausedRotation;
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * explicitCharacter;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) NSSet *drawingLines;
@property (nonatomic, retain) NSData *positionsAsData;
@property (nonatomic, retain) PSDrawingGroup *parent;
@property (atomic) BOOL isSelected;
@end

@interface PSDrawingGroup (CoreDataGeneratedAccessors)

- (void)addPosition:(SRTPosition)position withInterpolation:(BOOL)shouldInterpolate;
- (void)flattenTranslation:(BOOL)translation rotation:(BOOL)rotation scale:(BOOL)scale betweenTime:(float)timeStart andTime:(float)timeEnd;
- (void)pauseUpdatesOfTranslation:(BOOL)translation rotation:(BOOL)rotation scale:(BOOL)scale;
- (void)unpauseAll;
- (SRTPosition*)positions;
- (int)positionCount;
- (void)getStateAtTime:(float)time
			  position:(SRTPosition*)pPosition
				  rate:(SRTRate*)pRate
		   helperIndex:(int*)pIndex;
- (SRTPosition)currentCachedPosition;
- (void)setCurrentCachedPosition:(SRTPosition)position;

- (void)addChildrenObject:(PSDrawingGroup *)value;
- (void)removeChildrenObject:(PSDrawingGroup *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

- (void)addDrawingLinesObject:(PSDrawingLine *)value;
- (void)removeDrawingLinesObject:(PSDrawingLine *)value;
- (void)addDrawingLines:(NSSet *)values;
- (void)removeDrawingLines:(NSSet *)values;

- (void)applyTransform:(CGAffineTransform)transform;
- (CGRect)boundingRect;

- (GLKMatrix4)currentModelViewMatrix;
- (GLKMatrix4)getInverseMatrixToDocumentRoot;

- (BOOL)eraseAtPoint:(CGPoint)p;
- (BOOL)hitsPoint:(CGPoint)p;

- (void)deleteSelectedChildren;
- (void)mergeSelectedChildrenIntoNewGroup;
- (PSDrawingGroup*)topLevelSelectedChild;
- (void)breakUpGroupAndMergeIntoParent;


- (void)printSelected:(int)depth;

@end
