//
//  PSAnimationRenderingController.m
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-13.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import "PSAnimationRenderingController.h"



/* Private Interface */
@interface PSAnimationRenderingController ()
@property (strong, nonatomic, retain) EAGLContext* context;
@property (strong, retain) GLKBaseEffect* effect;
@end


/* Begin Implementation */
@implementation PSAnimationRenderingController
@synthesize context = _context;
@synthesize effect = _effect;


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
		
}


@end
