/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


enum
{
	// indices into _uniforms array for tracking uniform handles in our shaders
	UNIFORMS_MODELMATRIX,
	UNIFORMS_BRUSH_COLOR,
	NUM_UNIFORMS
};


#import "PSAnimationRenderingController.h"
#import "PSAppDelegate.h"
#import "PSHelpers.h"

/* Private Interface */
@interface PSAnimationRenderingController ()
{
	GLuint _program;
	GLint _uniforms[NUM_UNIFORMS];
	GLKMatrix4 _projectionMatrix;
	NSTimeInterval _currentTimeContinuous;
}
@property (strong, nonatomic, retain) EAGLContext* context;
@end



/* Begin Implementation */

@implementation PSAnimationRenderingController
@synthesize context = _context;
@synthesize rootGroup = _rootGroup;
@synthesize playing = _playing;
@synthesize selectionHelper = _selectionHelper;



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
	
	//Compile our shaders for drawing
	if (! [self loadShaders] )
	{
		[PSHelpers failWithMessage:@"Failed to load shaders in PSAnimationRenderingController"];
	}
	
	
	//TEMPORARY:
	[self startPlayingAtFrame:0];
	
}


- (void)startPlayingAtFrame:(int)frame
{
	[self.rootGroup jumpToFrame:frame];
	_currentTimeContinuous = frame;
	self.playing = YES;
}


- (int)currentFrame
{
	return (int)_currentTimeContinuous;
}

/*
	Generate our projection matrix in response to updates to our view's coordinates
*/
- (void)viewDidLayoutSubviews
{
    _projectionMatrix = GLKMatrix4MakeOrtho(
					  self.view.bounds.origin.x,
					  self.view.bounds.origin.x + self.view.bounds.size.width,
					  self.view.bounds.origin.y + self.view.bounds.size.height,
					  self.view.bounds.origin.y,
					  -1024, 1024);
}



/*	------------
 
 Delegate methods from the GLKView which trigger our rendering
 
 ------------*/
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{

	// Try to do as much rendering setup as possible so we don't have to call 
	// on each line/group when we recurse:
	
	// Use our custom shaders
	glUseProgram(_program);

	// Clear the background
	glClearColor(PSANIM_BACKGROUND_COLOR);
	glClear(GL_COLOR_BUFFER_BIT);
	
	// Set a blend function so our brush will have alpha preserved
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	
	// Push the projection matrix
	glUniformMatrix4fv(_uniforms[UNIFORMS_MODELMATRIX], 1, 0, _projectionMatrix.m);
	
	// Set the brush's color
	glUniform4f(_uniforms[UNIFORMS_BRUSH_COLOR], PSANIM_LINE_COLOR);
	
	// Now we can recurse on our root and will only have to push vertices and matrices
	[self.rootGroup renderGroupWithMatrix:_projectionMatrix uniforms:_uniforms];

	
	// Draw our selected lines again, with a different color to show them highlighted
	// It may seem crazy to draw selected lines twice per frame, but it isn't that
	// bad and saves us having to do expensive comparisons against the selected set
	// or maintaining thread-safety while running selection code in the background
	if (self.selectionHelper.selectedLines.count > 0)
	{
		//Set the brush's color for highlighting
		glUniform4f(_uniforms[UNIFORMS_BRUSH_COLOR], PSANIM_SELECTED_LINE_COLOR);
		glUniformMatrix4fv(_uniforms[UNIFORMS_MODELMATRIX], 1, 0, _projectionMatrix.m);
		
		for (PSDrawingLine* line in self.selectionHelper.selectedLines)
			[line renderWithUniforms:_uniforms overrideColor:YES];
	}

	
	//Draw our selection line on top of everything
	if(self.selectionHelper.selectionLoupeLine)
	{
		//Set the brush's color and size for selection loupe
		glUniform4f(_uniforms[UNIFORMS_BRUSH_COLOR], PSANIM_SELECTION_LOOP_COLOR);
		
		//Restore our default matrix
		glUniformMatrix4fv(_uniforms[UNIFORMS_MODELMATRIX], 1, 0, _projectionMatrix.m);

		[self.selectionHelper.selectionLoupeLine renderWithUniforms:_uniforms overrideColor:YES];
	}

}

- (void)update
{
	if(_playing)
	{
		_currentTimeContinuous += self.timeSinceLastUpdate;
		[self.rootGroup updateWithTimeInterval:self.timeSinceLastUpdate 
										toTime:_currentTimeContinuous];
	}
}



/*
 -------------------------------------------------------------------------------
 Helpers for loading, compiling, and linking our shaders
 (These are taken from the XCode template for an OpenGL project, if you want 
 more context, just create a new one and see how its supposed to be used)
 -------------------------------------------------------------------------------
*/

- (BOOL)loadShaders
{
	GLuint vertShader, fragShader;
	NSString *vertShaderPathname, *fragShaderPathname;

	// Create shader program.
	_program = glCreateProgram();

	// Create and compile vertex shader.
	vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
	if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
	{
		NSLog(@"Failed to compile vertex shader");
		return NO;
	}

	// Create and compile fragment shader.
	fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
	if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
	{
		NSLog(@"Failed to compile fragment shader");
		return NO;
	}

	// Attach vertex shader to program.
	glAttachShader(_program, vertShader);

	// Attach fragment shader to program.
	glAttachShader(_program, fragShader);

	// Bind attribute locations.
	// TODO: need this?
	// This needs to be done prior to linking.
	//    glBindAttribLocation(_program, ATTRIB_POSITION, "position");

	// Link program.
	if (![self linkProgram:_program])
	{
		NSLog(@"Failed to link program: %d", _program);

		// Clean up on failure
		
		if (vertShader)
		{
			glDeleteShader(vertShader);
			vertShader = 0;
		}

		if (fragShader)
		{
			glDeleteShader(fragShader);
			fragShader = 0;
		}

		if (_program)
		{
			glDeleteProgram(_program);
			_program = 0;
		}

		return NO;
	}

	// Get uniform locations
	// This are the addresses we can use later for passing arguments into the shader program
	_uniforms[UNIFORMS_MODELMATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
	_uniforms[UNIFORMS_BRUSH_COLOR] = glGetUniformLocation(_program, "brushColor");

	// Release vertex and fragment shaders.
	if (vertShader)
	{
		glDetachShader(_program, vertShader);
		glDeleteShader(vertShader);
	}

	if (fragShader)
	{
		glDetachShader(_program, fragShader);
		glDeleteShader(fragShader);
	}

	return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
	GLint status;
	const GLchar *source;

	source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
	if (!source)
	{
		NSLog(@"Failed to load vertex shader");
		return NO;
	}

	*shader = glCreateShader(type);
	glShaderSource(*shader, 1, &source, NULL);
	glCompileShader(*shader);

	#if defined(DEBUG)
	GLint logLength;
	glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetShaderInfoLog(*shader, logLength, &logLength, log);
		NSLog(@"Shader compile log:\n%s", log);
		free(log);
	}
	#endif

	glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		glDeleteShader(*shader);
		return NO;
	}

	return YES;
}


- (BOOL)linkProgram:(GLuint)prog
{
	GLint status;
	glLinkProgram(prog);

	#if defined(DEBUG)
	GLint logLength;
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program link log:\n%s", log);
		free(log);
	}
	#endif

	glGetProgramiv(prog, GL_LINK_STATUS, &status);
	if (status == 0)
	{
		return NO;
	}

	return YES;
}


- (BOOL)validateProgram:(GLuint)prog
{
	GLint logLength, status;

	glValidateProgram(prog);
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s", log);
		free(log);
	}

	glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
	if (status == 0)
	{
		return NO;
	}

	return YES;
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

- (void)jumpToFrame:(int)frame
{
	currentLocationIndex = 0;
	
	//Advance to the location <= frame
	while (currentLocationIndex + 1 < locationCount &&
		   frame > locationList[currentLocationIndex + 1].frame )
	{
		currentLocationIndex++;
	}
	
	SRTPosition currentPos = locationList[currentLocationIndex];
	
	// Set position and momentum
	if (locationCount == 0)
	{
		currentSRTPosition = SRTPositionZero();
		currentSRTRate = SRTRateZero();
	}
	else if ( (currentLocationIndex == 0 && currentPos.frame > frame) ||
			  (currentLocationIndex + 1 >= locationCount) )
	{
		currentSRTPosition = currentPos;
		currentSRTRate = SRTRateZero();
	}
	else
	{
		SRTPosition nextPos = locationList[currentLocationIndex+1];
		currentSRTPosition = SRTPositionInterpolate(frame, currentPos, nextPos);
		currentSRTRate = SRTRateInterpolate(currentPos, nextPos);
	}
	
	//Recurse!
	for (PSDrawingGroup* child in self.children)
	{
		[child jumpToFrame:frame];
	}

}

- (void)renderGroupWithMatrix:(GLKMatrix4)parentModelMatrix uniforms:(GLint*)uniforms
{
	//Push Matrix
	GLKMatrix4 ownModelMatrix = GLKMatrix4Multiply(parentModelMatrix, currentModelViewMatrix);
	glUniformMatrix4fv(uniforms[UNIFORMS_MODELMATRIX], 1, 0, ownModelMatrix.m);

	
	//Draw our own drawingLines
	for(PSDrawingLine* drawingItem in self.drawingLines)
	{
		//This call makes sure that our object is fetched into memory
		//It is only necessary because we are caching the points ourselves
		//Usually this is done automatically when you access properties on the object
		//TODO: take this out of the draw loop into somewhere else...
		//		or at least just make an accessor for points
		[drawingItem willAccessValueForKey:nil];	
		[drawingItem renderWithUniforms:uniforms overrideColor:NO];
	}
	
	//Recurse on child groups
	for (PSDrawingGroup* child in self.children)
		[child renderGroupWithMatrix:ownModelMatrix uniforms:uniforms];

}


- (void)updateWithTimeInterval:(NSTimeInterval)timeSinceLastUpdate toTime:(NSTimeInterval)currentTime
{

	// Check if it is time for us to advance
	BOOL shouldAdvance = ( currentLocationIndex + 1 < locationCount ) &&
						 ( locationList[currentLocationIndex + 1].frame <= currentTime );
	
	if( shouldAdvance )
	{
		NSLog(@"ADVANCING!");
		currentLocationIndex ++;
		
		if ( currentLocationIndex == locationCount - 1 )
		{
			currentSRTPosition = locationList[currentLocationIndex];
			currentSRTRate = SRTRateZero();
		}
		else
		{
			SRTPosition currentPos = locationList[currentLocationIndex];
			SRTPosition nextPos = locationList[currentLocationIndex + 1];
			currentSRTPosition = SRTPositionInterpolate(currentTime, currentPos, nextPos);
			currentSRTRate = SRTRateInterpolate(currentPos, nextPos);
		}
	} 
	else
	{
		// Animate with the current matrix
		currentSRTPosition.location.x += timeSinceLastUpdate * currentSRTRate.locationRate.x;
		currentSRTPosition.location.y += timeSinceLastUpdate * currentSRTRate.locationRate.y;
		currentSRTPosition.rotation += timeSinceLastUpdate * currentSRTRate.rotationRate;
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
- (void) renderWithUniforms:(GLint*)uniforms overrideColor:(BOOL)overrideColor
{	
	//Pass the vertices
	glEnableVertexAttribArray(GLKVertexAttribPosition);
	glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0,(void *)points );

	
	// Set the brush color
	if (!overrideColor)
	{
		UInt64 colorAsInt = [self.color unsignedLongLongValue];
		float r,g,b,a;
		[PSHelpers  int64ToColor:colorAsInt toR:&r g:&g b:&b a:&a];
		glUniform4f(uniforms[UNIFORMS_BRUSH_COLOR], r, g, b, a);		
	}
	
	// do actual drawing!
	glEnable(GL_TEXTURE_2D);
	glEnable (GL_BLEND);
	glBlendFunc (GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, pointCount);
	glDisable(GL_TEXTURE_2D);
	glDisableVertexAttribArray(GLKVertexAttribPosition);

}

@end



