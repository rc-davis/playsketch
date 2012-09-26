/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <GLKit/GLKit.h>
#import "PSDataModel.h"

/*
	This protocol is what a drawingDelegate needs to implement to help this class function
	The PSSceneViewController will be the one to implement this.
	This delegate design pattern lets us keep a ton of unrelated logic out of this object,
	whose only skill should be turning touches into points
*/
@protocol PSDrawingEventsViewDrawingDelegate <NSObject>
-(PSDrawingLine*)newLineToDrawTo:(id)drawingView;
-(void)addedToLine:(PSDrawingLine*)line fromPoint:(CGPoint)from toPoint:(CGPoint)to inDrawingView:(id)drawingView;
-(void)finishedDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView;
-(void)cancelledDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView;
-(void)movedAt:(CGPoint)p inDrawingView:(id)drawingView;
-(void)whileDrawingLine:(PSDrawingLine*)line tappedAt:(CGPoint)p tapCount:(int)tapCount inDrawingView:(id)drawingView;
@end


@interface PSDrawingEventsView : GLKView

@property(nonatomic,weak)IBOutlet id<PSDrawingEventsViewDrawingDelegate> drawingDelegate;
@property(nonatomic,retain)PSDrawingLine* currentLine;

@end
