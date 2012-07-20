/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#ifndef PlaySketch_PSPrimitiveDataStructs_h
#define PlaySketch_PSPrimitiveDataStructs_h

#import <GLKit/GLKMath.h>

typedef struct
{
	GLKVector2 location; // in Parent's coordinates
	float scale;
	float rotation;
	GLKVector2 origin; // point in own coordinates that location is measured to
} SRTPosition;


typedef struct
{
	GLKVector2 locationRate; // in Parent's coordinates
	float scaleRate; //about center
	float rotationRate; // about center
} SRTRate;


// Helpers for making

static inline SRTPosition SRTPositionMake(float x, float y, float scale, float rotation,
							float originX, float originY)
{
	SRTPosition p;
	p.location.x = x;
	p.location.y = y;
	p.scale = scale;
	p.rotation = rotation;
	p.origin.x = originX;
	p.origin.y = originY;
	return p;
}


static inline SRTRate SRTRateMake(float dX, float dY, float scaleRate, float rotationRate)
{
	SRTRate r;
	r.locationRate.x = dX;
	r.locationRate.y = dY;
	r.scaleRate = scaleRate;
	r.rotationRate = rotationRate;
	return r;
}

#endif
