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
#define PS_FAIL(message) { DEBUG_DISPLAY_FAILURE_MESSAGE(message); }
#define PS_ASSERT( expr, message) { if ( !(expr) ) DEBUG_DISPLAY_FAILURE_MESSAGE(message); }


static inline void DEBUG_DISPLAY_FAILURE_MESSAGE(NSString* message)
{
	[[[UIAlertView alloc] initWithTitle:@"FAILURE" 
								message:[NSString stringWithFormat:@"Execution will be unreliable after this point! Note this message:\n\"%@\"", message]
							   delegate:nil 
					  cancelButtonTitle:@"SORRY"
					  otherButtonTitles:nil, nil] show];

}

#endif