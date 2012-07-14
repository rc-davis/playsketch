/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


//TODO: conditionally remove this in non-debug builds
#define PS_ASSERT( expr, message) NSAssert( expr, message);
#define PS_ASSERT1( expr, message, arg) NSAssert1( expr, message, arg);
#define PS_NOT_YET_IMPLEMENTED() NSAssert(NO, @"NOT YET IMPLEMENTED" );
