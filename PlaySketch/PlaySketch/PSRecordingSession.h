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

@class PSDrawingGroup;

@interface PSRecordingSession : NSObject

- (id)initWithTranslation:(BOOL)overwriteTranslation
				 rotation:(BOOL)overwriteRotation
					scale:(BOOL)overwriteScale
		   startingAtTime:(float)startTime;
- (void)addGroupToSession:(PSDrawingGroup*)g;
- (void)transformAllGroupsByX:(float)dX
						 andY:(float)dY
					 rotation:(float)dRotation
						scale:(float)dScale
					   atTime:(float)time;
- (void)finishAtTime:(float)time;

@end
