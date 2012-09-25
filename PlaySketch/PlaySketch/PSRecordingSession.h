//
//  PSRecordingSession.h
//  PlaySketch
//
//  Created by Ryder Ziola on 2012-09-25.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

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
