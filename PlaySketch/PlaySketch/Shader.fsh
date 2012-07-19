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

 This is our custom fragment shader, using a point-sprite effect to draw brushes.
 It is provided with a 'fragment' located at gl_PointCoord by the vertex shader and
 draws the brush image there without any rotation or scaling.
 The image is specified by setting the 'brushTexture' uniform variable.
 
 I found this tutorial to provide a helpful introduction to using OpenGL ES 2.0:
 http://iphonedevelopment.blogspot.sg/2010/11/opengl-es-20-for-ios-chapter-4.html

 */

uniform sampler2D brushTexture;

void main()
{
    gl_FragColor = texture2D(brushTexture, gl_PointCoord);
}
