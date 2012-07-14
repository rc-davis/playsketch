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
#import "PSAnimationRenderingView.h"


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

	[self setOrCreateRoot];
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


// TODO: This is temporary until we have drawing functionality
// This should be done by the parent view controller hosting us
-(void)setOrCreateRoot
{
	PSAppDelegate* appDelegate = (PSAppDelegate*)[[UIApplication sharedApplication] delegate];	
	NSManagedObjectContext *context = [appDelegate managedObjectContext];
	
	self.rootGroup = [appDelegate rootDrawingGroup];
	
	//Query for a root object to see if we need to create anything	
	if( self.rootGroup == nil )
	{
		//Create a new root object
		NSLog(@"createTestData: Found NO root group, creating..." );
		
		PSDrawingGroup* newRoot = (PSDrawingGroup*)[NSEntityDescription 
													insertNewObjectForEntityForName:@"PSDrawingGroup" inManagedObjectContext:context];
		//Set its properties
		newRoot.rootGroup = [NSNumber numberWithBool:YES];
		newRoot.name = @"auto-generated Root";
		
		//Save
		 NSError *error;
		 if (![context save:&error])
			 NSLog(@"Failed to save context!: %@", [error localizedDescription]);
		
		self.rootGroup = newRoot;
		
		[context save:nil]; //TODO: catch error

	}		

	((PSAnimationRenderingView*)self.view).currentGroup = self.rootGroup;

}


/*	------------
 
	Update & Rendering Code!
	Here we walk the tree of PSDrawingGroups and render them
	We are centralizing all of this code here to keep it out of the data model classes
	TODO: Should these be plain C functions to avoid the overhead of objective-C message passing
	in the highly time-sensitive render loops?

	------------*/

-(void)renderGroup:(PSDrawingGroup*)group
{
	//TODO: PUSH
	//self.effect.transform.modelviewMatrix = self.modelMatrix;
	
	for(PSDrawingLine* drawingItem in group.drawingLines)
	{
		//This call makes sure that our object is fetched into memory
		//It is only necessary because we are caching the points ourselves
		//Usually this is done automatically when you access properties on the object
		//TODO: take this out of the draw loop into somewhere else...
		[drawingItem willAccessValueForKey:nil];
	
		[drawingItem render];
	}
	
	// Recurse down to the children
	for (PSDrawingGroup* child in group.children)
	{
		[self renderGroup:child];
	}
	
	//TODO: POP
}


-(void)updateGroup:(PSDrawingGroup*)group withTimeInterval:(NSTimeInterval)timeSinceLastUpdate
{
	// Update our drawing Items
	for(PSDrawingLine* drawingItem in group.drawingLines)
		;//TODO: [drawingItem update]
		
	// Recurse down to the children
	for (PSDrawingGroup* child in group.children)
	{
		[self updateGroup:child withTimeInterval:timeSinceLastUpdate];
	}
}


/*	------------
 
	Delegate methods from the GLKView to do our rendering
 
	------------*/

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {    

    glClearColor(0.5, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
	
	// Try to do as much rendering setup as possible so we don't have to call it on every iteration
	[self.effect prepareToDraw];
	self.effect.useConstantColor = YES;
	self.effect.constantColor = GLKVector4Make(0.0, 1.0, 1.0, 0.5);

	[self renderGroup:self.rootGroup];
}

- (void)update
{
	[self updateGroup:self.rootGroup withTimeInterval:self.timeSinceLastUpdate];
}
 



@end


/*	------------

	Define the actual rendering code for the classes we are drawing here.
	(We can dynamically add methods to a class using the objective-c feature called "Categories")
	TODO: would really like to be able to do this with less message passing
	
	------------*/

@implementation PSDrawingLine ( renderingCategory )
-(void)render
{	
	//Set the vertices
	glEnableVertexAttribArray(GLKVertexAttribPosition);
	glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0,(void *)points );
	
	//Draw the vertices
	glDrawArrays(GL_LINE_STRIP, 0, pointCount);
	
	//Release our vertex array
	glDisableVertexAttribArray(GLKVertexAttribPosition);
	
}



@end
