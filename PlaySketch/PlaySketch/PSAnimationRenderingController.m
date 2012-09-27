/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSAnimationRenderingController.h"
#import "PSAppDelegate.h"
#import "PSHelpers.h"
#import "PSGraphicConstants.h"

/* Private Interface */
@interface PSAnimationRenderingController ()
{
	GLKMatrix4 _projectionMatrix;
	NSTimeInterval _currentTimeContinuous;
}
@property (strong, nonatomic, retain) EAGLContext* context;
@property (strong) GLKBaseEffect * effect;
@end


/* Begin Implementation */

@implementation PSAnimationRenderingController

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (void)viewDidLoad
{

	// Create an OpenGL Rendering Context
	self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	
	if (!self.context)
	{
		[PSHelpers failWithMessage:@"Failed to created an OpenGL context"];
    }

	// Tell our view about the context
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];

	// Create an effect instead of our own shaders
	self.effect = [[GLKBaseEffect alloc] init];
	self.effect.useConstantColor = GL_TRUE;

}


- (void)playFromTime:(float)time
{
	[self.currentDocument.rootGroup jumpToTime:time];
	_currentTimeContinuous = time;
	self.playing = YES;
}


- (void)jumpToTime:(float)time
{
	[self.currentDocument.rootGroup jumpToTime:time];
	_currentTimeContinuous = time;
	self.playing = NO;	
}


- (void)stopPlaying
{
	self.playing = NO;
}

/*
	Generate our projection matrix in response to updates to our view's coordinates
*/
- (void)viewDidLayoutSubviews
{
	_projectionMatrix = GLKMatrix4MakeOrtho(
					-self.view.bounds.size.width/2.0,
					self.view.bounds.size.width/2.0,
					self.view.bounds.size.height/2.0,
					-self.view.bounds.size.height/2.0,
					-1024, 1024);
}



/*	------------
 
 Delegate methods from the GLKView which trigger our rendering
 
 ------------*/
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	// Clear the background
	glClearColor(BACKGROUND_COLOR);
	glClear(GL_COLOR_BUFFER_BIT);
	
	self.effect.transform.projectionMatrix = _projectionMatrix;
	
	// Recurse on our root and will only have to push vertices and matrices
	[self.currentDocument.rootGroup renderGroupWithEffect:self.effect matrix:GLKMatrix4Identity isSelected:NO];
	
	//Draw our selection line on top of everything
	if(self.currentLine)
	{
		self.effect.transform.modelviewMatrix = GLKMatrix4Identity;
		[self.currentLine renderWithEffect:self.effect isSelected:NO];
	}
}

- (void)update
{
	NSTimeInterval elapsedGameTime = self.playing ? self.timeSinceLastUpdate : 0.0;
	_currentTimeContinuous += elapsedGameTime;
	[self.currentDocument.rootGroup updateWithTimeInterval:elapsedGameTime
									toTime:_currentTimeContinuous];
}

@end




/*	------------
 
	Update & Rendering Code!
	We are centralizing all of the rendering code here to keep it out of the data model classes
	PSDrawingGroups set the transforms, trigger their drawing/lines to render,
	then recurse.
 
	(We are dynamically adding methods to the group and line classes using the 
	objective-c feature called "Categories")

	If performance is becoming an issue, consider making these plain C functions to avoid the 
	overhead of objective-C message passing.

	------------*/

@implementation PSDrawingGroup ( renderingCategory )

- (void)jumpToTime:(float)time
{
	[self getStateAtTime:time
				position:&currentSRTPosition
					rate:&currentSRTRate
			 helperIndex:&currentPositionIndex];
	
	//Recurse!
	for (PSDrawingGroup* child in self.children)
	{
		[child jumpToTime:time];
	}

}

- (void)renderGroupWithEffect:(GLKBaseEffect*)effect matrix:(GLKMatrix4)parentMatrix isSelected:(BOOL)isSelected
{
	// If we are not currently visible, quit now and don't do any work
	if (!currentSRTPosition.isVisible) return;
	
	isSelected = self.isSelected || isSelected;
	
	//Push Matrix
	GLKMatrix4 ownModelMatrix = GLKMatrix4Multiply(parentMatrix, currentModelViewMatrix);
	effect.transform.modelviewMatrix = ownModelMatrix;

	//Draw our own drawingLines
	for(PSDrawingLine* drawingItem in self.drawingLines)
		[drawingItem renderWithEffect:effect isSelected:isSelected];

	//Recurse on child groups
	for (PSDrawingGroup* child in self.children)
		[child renderGroupWithEffect:effect matrix:ownModelMatrix isSelected:isSelected];
}


- (void)updateWithTimeInterval:(NSTimeInterval)timeSinceLastUpdate toTime:(NSTimeInterval)currentTime
{
	// Check if it is time for us to advance
	BOOL shouldAdvance = ( currentPositionIndex + 1 < self.positionCount ) &&
						 ( self.positions[currentPositionIndex + 1].timeStamp <= currentTime );
	
	if( shouldAdvance )
	{
		currentPositionIndex ++;
		
		if ( currentPositionIndex == self.positionCount - 1 )
		{
			currentSRTPosition = self.positions[currentPositionIndex];
			currentSRTRate = SRTRateZero();
		}
		else
		{
			SRTPosition currentPos = self.positions[currentPositionIndex];
			SRTPosition nextPos = self.positions[currentPositionIndex + 1];
			SRTPosition newCurrentPosition = SRTPositionInterpolate(currentTime, currentPos, nextPos);
			if(_pausedTranslation)newCurrentPosition.location = currentSRTPosition.location;
			if(_pausedRotation)newCurrentPosition.rotation = currentSRTPosition.rotation;
			if(_pausedScale)newCurrentPosition.scale = currentSRTPosition.scale;
			currentSRTPosition = newCurrentPosition;
			currentSRTRate = SRTRateInterpolate(currentPos, nextPos);
		}
	} 
	else
	{
		// Animate with the current matrix
		if(!_pausedTranslation)
		{
			currentSRTPosition.location.x += timeSinceLastUpdate * currentSRTRate.locationRate.x;
			currentSRTPosition.location.y += timeSinceLastUpdate * currentSRTRate.locationRate.y;
		}
		if(!_pausedRotation)
			currentSRTPosition.rotation += timeSinceLastUpdate * currentSRTRate.rotationRate;
		if(!_pausedScale)
			currentSRTPosition.scale += timeSinceLastUpdate * currentSRTRate.scaleRate;
	}
	
	// Set current group matrix
	GLKMatrix4 m = GLKMatrix4Identity;

	m = GLKMatrix4Translate(m, currentSRTPosition.location.x, currentSRTPosition.location.y, 0);
	m = GLKMatrix4Scale(m, currentSRTPosition.scale, currentSRTPosition.scale, 1);
	m = GLKMatrix4Rotate(m, currentSRTPosition.rotation, 0, 0, 1);
	m = GLKMatrix4Translate(m, -currentSRTPosition.origin.x, -currentSRTPosition.origin.y, 0);
	currentModelViewMatrix = m;

	// Recurse on our children
	for (PSDrawingGroup* child in self.children)
		[child updateWithTimeInterval:timeSinceLastUpdate 
							   toTime:currentTime];

}

@end


/*
	Adding a render function for the Line class.
	The line doesn't need to deal with its geometry matrix, because the group
	it belongs to does all of that configuration once for all of the lines that
	are in its coordinate space.
 
 */
@implementation PSDrawingLine ( renderingCategory )
- (void) renderWithEffect:(GLKBaseEffect*)effect isSelected:(BOOL)isSelected
{	
	// Set the brush color
	if(isSelected)
	{
		effect.constantColor = GLKVector4Make(SELECTION_COLOR);
	}
	else
	{
		float r,g,b,a;
		[PSHelpers  int64ToColor:[self.color unsignedLongLongValue] toR:&r g:&g b:&b a:&a];
		effect.constantColor = GLKVector4Make(r, g, b, a);
	}

	[effect prepareToDraw];
	
	//Pass the vertices
	glEnableVertexAttribArray(GLKVertexAttribPosition);
	glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0,(void *)self.points);
	
	// do actual drawing!
    glDrawArrays(GL_TRIANGLE_STRIP, 0, self.pointCount);
	glDisableVertexAttribArray(GLKVertexAttribPosition);

}

@end
