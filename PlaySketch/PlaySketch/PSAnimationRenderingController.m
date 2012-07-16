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


/* Private Interface */
@interface PSAnimationRenderingController ()

@property (strong, nonatomic, retain) EAGLContext* context;
@property (strong, retain) GLKBaseEffect* effect;

@end



/* Begin Implementation */
@implementation PSAnimationRenderingController
@synthesize context = _context;
@synthesize effect = _effect;
@synthesize rootGroup = _rootGroup;


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
        NSLog(@"!!!! Failed to create an OpenGL ES context!!!!");
    }

	// Tell our view about the context
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    

	// Create a default "effect" for rendering
	// GLKBaseEffect gives us basic texture and lights, which should be good enough
    self.effect = [[GLKBaseEffect alloc] init];

}


/*
	Generate our projection matrix in response to updates to our view's coordinates
*/
- (void)viewDidLayoutSubviews
{
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(
					  self.view.bounds.origin.x,
					  self.view.bounds.origin.x + self.view.bounds.size.width,
					  self.view.bounds.origin.y,
					  self.view.bounds.origin.y + self.view.bounds.size.height,
					  -1024, 1024);
    self.effect.transform.projectionMatrix = projectionMatrix;
}



/*	------------
 
 Delegate methods from the GLKView which trigger our rendering
 
 ------------*/

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {    
	
    glClearColor(1.0, 0.977, 0.842, 1.00);
    glClear(GL_COLOR_BUFFER_BIT);    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
	
	// Try to do as much rendering setup as possible so we don't have to call it on every iteration
	self.effect.useConstantColor = YES;
	self.effect.constantColor = GLKVector4Make(0.5, 0.5, 0.5, 1.0);
	self.effect.transform.modelviewMatrix = GLKMatrix4Identity;

	[self.rootGroup renderGroupWithEffect:self.effect];

}

- (void)update
{
	[self.rootGroup updateWithTimeInterval:self.timeSinceLastUpdate];
}

@end


/*	------------
 
	Update & Rendering Code!
	We are centralizing all of the rendering code here to keep it out of the data model classes
	PSDrawingGroups set the transforms, trigger their drawing/lines to render,
	then recurse.
 
	(We are dynamically adding methods to the group and line classes using the 
	objective-c feature called "Categories")

	TODO: Should these be plain C functions to avoid the overhead of objective-C message passing
	in the highly time-sensitive render loops?
	At least with much less message passing

	------------*/


@implementation PSDrawingGroup ( renderingCategory )
- (void) renderGroupWithEffect:(GLKBaseEffect*)effect
{
	//Push Matrix
	GLKMatrix4 previousMatrix = effect.transform.modelviewMatrix;
	effect.transform.modelviewMatrix = GLKMatrix4Multiply(previousMatrix, 
														  currentModelViewMatrix);
	[effect prepareToDraw];	

	
	//Draw our own drawingLines
	for(PSDrawingLine* drawingItem in self.drawingLines)
	{
		//This call makes sure that our object is fetched into memory
		//It is only necessary because we are caching the points ourselves
		//Usually this is done automatically when you access properties on the object
		//TODO: take this out of the draw loop into somewhere else...
		[drawingItem willAccessValueForKey:nil];	

		[drawingItem render];
	}
	
	
	//Recurse on child groups
	for (PSDrawingGroup* child in self.children)
		[child renderGroupWithEffect:effect];


	//Pop Matrix
	effect.transform.modelviewMatrix = previousMatrix;
	
}


- (void) updateWithTimeInterval:(NSTimeInterval)timeSinceLastUpdate
{
	// Animate
	currentSRTPosition.location.x += timeSinceLastUpdate * currentSRTRate.locationRate.x;
	currentSRTPosition.location.y += timeSinceLastUpdate * currentSRTRate.locationRate.y;
	currentSRTPosition.rotation += timeSinceLastUpdate * currentSRTRate.rotationRate;
	currentSRTPosition.scale += timeSinceLastUpdate * currentSRTRate.scaleRate;

	// Set current group matrix
	GLKMatrix4 m = GLKMatrix4Identity;

	m = GLKMatrix4Translate(m, currentSRTPosition.location.x, currentSRTPosition.location.y, 0);
//	m = GLKMatrix4Translate(m, currentSRTPosition.origin.x, currentSRTPosition.origin.y, 0);
	m = GLKMatrix4Scale(m, currentSRTPosition.scale, currentSRTPosition.scale, 1);
	m = GLKMatrix4Rotate(m, currentSRTPosition.rotation, 0, 0, 1);
	m = GLKMatrix4Translate(m, -currentSRTPosition.origin.x, -currentSRTPosition.origin.y, 0);
	currentModelViewMatrix = m;

	
	// Recurse on our children
	for (PSDrawingGroup* child in self.children)
		[child updateWithTimeInterval:timeSinceLastUpdate];

}

@end


/*
	Adding a render function for the Line class.
	The line doesn't need to deal with its geometry matrix, because the group
	it belongs to does all of that configuration once for all of the lines that
	are in its coordinate space.
 
 */
@implementation PSDrawingLine ( renderingCategory )
- (void) render
{	

	//Pass the vertices
	glEnableVertexAttribArray(GLKVertexAttribPosition);
	glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0,(void *)points );
	
	//Draw the vertices
	glDrawArrays(GL_LINE_STRIP, 0, pointCount);
	
	//Release our vertex array
	glDisableVertexAttribArray(GLKVertexAttribPosition);
	
}

@end



