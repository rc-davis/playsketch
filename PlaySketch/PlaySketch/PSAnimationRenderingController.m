//
//  PSAnimationRenderingController.m
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-13.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

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
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, 480, 0, 320, -1024, 1024);
    self.effect.transform.projectionMatrix = projectionMatrix;

	[self setOrCreateRoot];
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

	}	
	
	//TEMP: add one drawing line
	PSDrawingItem* newItem = (PSDrawingItem*)[NSEntityDescription 
												insertNewObjectForEntityForName:@"PSDrawingItem" inManagedObjectContext:context];
	newItem.group = self.rootGroup;
	[context save:nil];

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
	
	for(PSDrawingItem* drawingItem in group.drawingItems)
	{
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
	for(PSDrawingItem* drawingItem in group.drawingItems)
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
