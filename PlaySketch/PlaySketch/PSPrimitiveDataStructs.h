//
//  PSPrimitiveDataStructs.h
//  PlaySketch
//
//  Created by Ryder Ziola on 12-07-14.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#ifndef PlaySketch_PSPrimitiveDataStructs_h
#define PlaySketch_PSPrimitiveDataStructs_h

#import <GLKit/GLKMath.h>

typedef struct
{
	GLKVector2 location; // in Parent's coordinates
	float scale;
	float rotation;
	GLKVector2 center; //in Parent's coordinates
} SRTPosition;


typedef struct
{
	GLKVector2 locationRate; // in Parent's coordinates
	float scaleRate; //about center
	float rotationRate; // about center
} SRTRate;


// Helpers for making

static inline SRTPosition SRTPositionMake(float x, float y, float scale, float rotation,
							float centerX, float centerY)
{
	SRTPosition p;
	p.location.x = x;
	p.location.y = y;
	p.scale = scale;
	p.rotation = rotation;
	p.center.x = centerX;
	p.center.y = centerY;
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
