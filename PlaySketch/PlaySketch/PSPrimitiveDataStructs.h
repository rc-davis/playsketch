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
#import "PSHelpers.h"

typedef int SRTKeyframeType;

typedef struct
{
	float timeStamp; // The time to be at this position
	GLKVector2 location; // in Parent's coordinates
	float scale; // About origin
	float rotation; // About origin
	GLKVector2 origin; // point in own coordinates that location is measured to
	SRTKeyframeType keyframeType; // whether should be used to determine scope for interpolation
} SRTPosition;


typedef struct
{
	GLKVector2 locationRate; // in Parent's coordinates
	float scaleRate; //about center
	float rotationRate; // about center
} SRTRate;


// Helpers for making

static inline SRTPosition SRTPositionMake(int timeStamp, float x, float y,
										  float scale, float rotation, 
										  float originX, float originY, SRTKeyframeType keyframeType)
{
	SRTPosition p;
	p.timeStamp = timeStamp;
	p.location.x = x;
	p.location.y = y;
	p.scale = scale;
	p.rotation = rotation;
	p.origin.x = originX;
	p.origin.y = originY;
	p.keyframeType = keyframeType;
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
	return SRTPositionMake(0, 0, 0, 1, 0, 0, 0, NO);
}

static inline SRTKeyframeType SRTKeyframeTypeNone()
{
	return 0;
}

static inline SRTKeyframeType SRTKeyframeAdd(SRTKeyframeType keyframe, BOOL scale, BOOL rotate, BOOL translate)
{
	if(scale) keyframe = keyframe | 1;
	if(rotate) keyframe = keyframe | 2;
	if(translate) keyframe = keyframe | 4;
	return keyframe;
}

static inline SRTKeyframeType SRTKeyframeMake(BOOL scale, BOOL rotate, BOOL translate)
{
	return SRTKeyframeAdd(SRTKeyframeTypeNone(), scale, rotate, translate);
}

static inline BOOL SRTKeyframeIsAny(SRTKeyframeType keyframe)
{
	return keyframe != 0;
}

static inline BOOL SRTKeyframeIsScale(SRTKeyframeType keyframe)
{
	return (keyframe & 1 ) != 0;
}

static inline BOOL SRTKeyframeIsRotation(SRTKeyframeType keyframe)
{
	return (keyframe & 2 ) != 0;
}

static inline BOOL SRTKeyframeIsTranslate(SRTKeyframeType keyframe)
{
	return (keyframe & 4 ) != 0;
}

static inline BOOL SRTKeyframeIsOnlyScale(SRTKeyframeType keyframe)
{
	return keyframe == 1;
}

static inline BOOL SRTKeyframeIsOnlyRotation(SRTKeyframeType keyframe)
{
	return keyframe == 2;
}

static inline BOOL SRTKeyframeIsOnlyTranslate(SRTKeyframeType keyframe)
{
	return keyframe == 4;
}

static inline SRTKeyframeType SRTKeyframeRemove(SRTKeyframeType keyframe, BOOL scale, BOOL rotate, BOOL translate)
{
	return SRTKeyframeMake(!scale && SRTKeyframeIsScale(keyframe),
							   !rotate && SRTKeyframeIsRotation(keyframe),
							   !translate && SRTKeyframeIsTranslate(keyframe));
}


static inline SRTKeyframeType SRTKeyframeAdd2(SRTKeyframeType keyframe1, SRTKeyframeType keyframe2)
{
	return SRTKeyframeAdd(keyframe1,
						  SRTKeyframeIsScale(keyframe2),
						  SRTKeyframeIsRotation(keyframe2),
						  SRTKeyframeIsTranslate(keyframe2));
}

static inline SRTPosition SRTPositionInterpolate(float time, SRTPosition p1, SRTPosition p2)
{
	[PSHelpers assert:(p1.timeStamp != p2.timeStamp) withMessage:@"Should be different times"];

//	TODO: Shouldn't have to disable this assert
//	[PSHelpers assert:(p1.timeStamp <= time &&
//					   p2.timeStamp >= time) withMessage:@"time should be within range"];

	float pcnt = (time - p1.timeStamp)/(float)(p2.timeStamp - p1.timeStamp);
	
	SRTPosition pos;
	pos.timeStamp = time;
	pos.location.x = (1 - pcnt) * p1.location.x + pcnt * p2.location.x;
	pos.location.y = (1 - pcnt) * p1.location.y + pcnt * p2.location.y;
	pos.scale = (1 - pcnt) * p1.scale + pcnt * p2.scale;
	pos.rotation = (1 - pcnt) * p1.rotation + pcnt * p2.rotation;
	pos.origin.x = (1 - pcnt) * p1.origin.y + pcnt * p2.origin.y;
	pos.origin.y = (1 - pcnt) * p1.origin.y + pcnt * p2.origin.y;
	pos.keyframeType = SRTKeyframeTypeNone();
	return pos;
}

static inline SRTRate SRTRateInterpolate(SRTPosition p1, SRTPosition p2)
{
	float frameSpan = p2.timeStamp - p1.timeStamp;
	SRTRate rate;
	rate.locationRate.x = (p2.location.x - p1.location.x)/frameSpan;
	rate.locationRate.y = (p2.location.y - p1.location.y)/frameSpan;
	rate.scaleRate = (p2.scale - p1.scale)/frameSpan;
	rate.rotationRate = (p2.rotation - p1.rotation)/frameSpan;
	return rate;
}

static inline SRTPosition SRTPositionGetDelta(SRTPosition p1, SRTPosition p2)
{
	SRTPosition delta = SRTPositionZero();
	
	delta.location.x = p2.location.x - p1.location.x;
	delta.location.y = p2.location.y - p1.location.y;	
	delta.scale = p2.scale - p1.scale;
	delta.rotation = p2.rotation - p1.rotation;
	delta.timeStamp = p2.timeStamp - p1.timeStamp;
	delta.origin.x = p2.origin.x - p1.origin.x;
	delta.origin.y = p2.origin.y - p1.origin.y;
	return delta;
}

static inline SRTPosition SRTPositionApplyDelta(SRTPosition p, SRTPosition delta, float pcnt)
{
	p.location.x += pcnt * delta.location.x;
	p.location.y += pcnt * delta.location.y;
	p.scale += pcnt * delta.scale;
	p.rotation += pcnt * delta.rotation;
	p.origin.x += pcnt * delta.origin.x;
	p.origin.y += pcnt * delta.origin.y;
	return p;
}

static inline SRTPosition SRTPositionFromTransform(CGAffineTransform t)
{
	SRTPosition p = SRTPositionZero();
	
	// Grab the translation directly from the transform
	p.location.x = t.tx;
	p.location.y = t.ty;

	// Project two points into the parent space using the transform to calculate rotation and scale
	CGPoint p1 = CGPointMake(0, 0);
	CGPoint p2 = CGPointMake(1, 0);
	CGPoint p1Parent = CGPointApplyAffineTransform(p1, t);
	CGPoint p2Parent = CGPointApplyAffineTransform(p2, t);	
	p.rotation = atan2f(p2Parent.y - p1Parent.y, p2Parent.x - p1Parent.x);
	p.scale = hypotf(p1Parent.x - p2Parent.x, p1Parent.y - p2Parent.y)/hypotf(p1.x - p2.x, p1.y - p2.y);
	
	// TODO: I don't think we need to use the origin points at all (yet?)
	p.origin.x = 0;
	p.origin.y = 0;
	
	
	return p;
}


static inline CGAffineTransform SRTPositionToTransform(SRTPosition p)
{
	CGAffineTransform t = CGAffineTransformIdentity;
	t = CGAffineTransformTranslate(t, p.location.x, p.location.y);
	t = CGAffineTransformScale(t, p.scale, p.scale);
	t = CGAffineTransformRotate(t, p.rotation);
	t = CGAffineTransformTranslate(t, -p.origin.x, -p.origin.y);
	return t;
}


static inline BOOL SRTPositionsEqual(SRTPosition p1, SRTPosition p2, BOOL ignoreTimestamp)
{
	BOOL timestampMatches = ignoreTimestamp || (p1.timeStamp == p2.timeStamp);
	return timestampMatches &&
			p1.location.x == p2.location.x &&
			p1.location.y == p2.location.y &&
			p1.rotation == p2.rotation &&
			p1.scale == p2.scale &&
			p1.origin.x == p2.origin.x &&
			p1.origin.y == p2.origin.y;
}

static inline CGPoint CGPointFromGLKVector4(GLKVector4 v)
{
	return CGPointMake(v.x, v.y);
}

static inline CGPoint CGPointFromGLKVector2(GLKVector2 v)
{
	return CGPointMake(v.x, v.y);
}


static inline GLKVector4 GLKVector4FromCGPoint(CGPoint p)
{
	return GLKVector4Make(p.x, p.y, 1.0, 1.0);
}

static inline GLKVector2 GLKVector2FromCGPoint(CGPoint p)
{
	return GLKVector2Make(p.x, p.y);
}


static inline CGPoint CGRectGetCenter(CGRect r)
{
	return CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r));
}

#endif
