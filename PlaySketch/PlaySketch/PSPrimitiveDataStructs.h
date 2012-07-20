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
	int frame; // The time to be at this position
	GLKVector2 location; // in Parent's coordinates
	float scale; // About origin
	float rotation; // About origin
	GLKVector2 origin; // point in own coordinates that location is measured to
} SRTPosition;


typedef struct
{
	GLKVector2 locationRate; // in Parent's coordinates
	float scaleRate; //about center
	float rotationRate; // about center
} SRTRate;


// Helpers for making

static inline SRTPosition SRTPositionMake(int frame, float x, float y, 
										  float scale, float rotation, 
										  float originX, float originY)
{
	SRTPosition p;
	p.frame = frame;
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

static inline SRTRate SRTRateZero()
{
	return SRTRateMake(0,0,0,0);
}

static inline SRTPosition SRTPositionZero()
{
	return SRTPositionMake(0, 0, 0, 1, 0, 0, 0);
}

static inline SRTPosition SRTPositionInterpolate(float frame, SRTPosition p1, SRTPosition p2)
{
	float pcnt = (frame - p1.frame)/(float)(p2.frame - p1.frame);
	
	SRTPosition pos;
	pos.frame = frame;
	pos.location.x = (1 - pcnt) * p1.location.x + pcnt * p2.location.x;
	pos.location.y = (1 - pcnt) * p1.location.y + pcnt * p2.location.y;
	pos.scale = (1 - pcnt) * p1.scale + pcnt * p2.scale;
	pos.rotation = (1 - pcnt) * p1.rotation + pcnt * p2.rotation;
	pos.origin.x = (1 - pcnt) * p1.origin.y + pcnt * p2.origin.y;
	pos.origin.y = (1 - pcnt) * p1.origin.y + pcnt * p2.origin.y;
	return pos;
}

static inline SRTRate SRTRateInterpolate(SRTPosition p1, SRTPosition p2)
{
	float frameSpan = p2.frame - p1.frame;
	SRTRate rate;
	rate.locationRate.x = (p2.location.x - p1.location.x)/frameSpan;
	rate.locationRate.y = (p2.location.y - p1.location.y)/frameSpan;
	rate.scaleRate = (p2.scale - p1.scale)/frameSpan;
	rate.rotationRate = (p2.rotation - p1.rotation)/frameSpan;
	NSLog(@"rotation rat: %lf", rate.rotationRate);
	return rate;
}


#endif
