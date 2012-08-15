/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSGLKitVideoExporter.h"
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>

@implementation PSGLKitVideoExporter


+ (PSGLKitVideoExporter*)beginWithView:(GLKView*)view
{
	return [[PSGLKitVideoExporter alloc] init];
	// Use AVAssetWriter to record the view
	
}

@end
