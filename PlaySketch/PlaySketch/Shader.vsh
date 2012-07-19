/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


/*
 
 This is our custom vertex shader.

 It just translates points using a modelView matrix in a really simple fashion.
 'position' provides the point.
 'modelViewProjectionMatrix' provides the matrix to project with.
 
 I found this tutorial to provide a helpful introduction to using OpenGL ES 2.0:
 http://iphonedevelopment.blogspot.sg/2010/11/opengl-es-20-for-ios-chapter-4.html
 
 Note: Before completion, gl_PointSize and gl_Position need to be set by the program.
 
 */

attribute vec4 position;
uniform mat4 modelViewProjectionMatrix;

void main()
{
    gl_PointSize = 40.0;
    gl_Position = modelViewProjectionMatrix * position;
}
