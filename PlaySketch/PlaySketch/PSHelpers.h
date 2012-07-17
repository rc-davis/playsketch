/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#ifndef PlaySketch_PSHelpers_h
#define PlaySketch_PSHelpers_h



//TODO: conditionally remove this in non-debug builds
#define PS_ASSERT( expr, message) NSAssert( expr, message);
#define PS_ASSERT1( expr, message, arg) NSAssert1( expr, message, arg);
#define PS_NOT_YET_IMPLEMENTED() NSAssert(NO, @"NOT YET IMPLEMENTED" );


// Translate a rect from top-0 to bottom-0 coordinate systems (urgh)
static inline CGRect CGRectByFlippingYOriginDirection(CGRect rect, CGRect parentFrame)
{
	return CGRectMake(rect.origin.x,
					  parentFrame.size.height - (rect.origin.y + rect.size.height),
					  rect.size.width,
					  rect.size.height);
}


#endif