/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


#import "PSVideoExportControllerViewController.h"
#import "PSGLKitVideoExporter.h"
#import "PSAnimationRenderingController.h"
#import "PSHelpers.h"

@interface PSVideoExportControllerViewController ()
@end

@implementation PSVideoExportControllerViewController
@synthesize progressIndicator = _progressIndicator;
@synthesize renderingController = _renderingController;
@synthesize completionLabel = _completionLabel;
@synthesize completionButton = _completionButton;


- (void)viewWillAppear:(BOOL)animated
{
	// Initialize our display
	self.progressIndicator.progress = 0;
	self.completionLabel.hidden = YES;
	self.completionButton.hidden = YES;
}


- (void)viewDidAppear:(BOOL)animated
{
	// Ensure we have the values we need
	[PSHelpers assert:(self.renderingController != nil)
		  withMessage:@"Need a renderingController"];
		
	// Then kick off a background thread to do the actual processing
	[self performSelectorInBackground:@selector(exportVideo) withObject:nil];

}


- (void)exportVideo
{
	// Bad things happen if the animations's render loop is running at the same time
	self.renderingController.paused = YES;
	
	// Generate a temporary URL for the video
	NSString* filename = [NSString stringWithFormat:@"%.0f.%@",
						  [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mp4"];
	NSString* filepath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
	

	// Create a new video exporter to do the work...
	PSGLKitVideoExporter* exporter = NULL;
	exporter = [[PSGLKitVideoExporter alloc] initWithView:(GLKView*)self.renderingController.view
																		 toPath:filepath];
	

	[exporter beginRecording];

	// Step through all of our frames and add them to the movie
	int frameNumber = 0;
	int totalFrames = 30*1; // TODO: GRAB THIS PROPERLY FROM THE RENDERING CONTROLLER

	while (frameNumber < totalFrames)
	{
		[self.renderingController jumpToTime:frameNumber/30.0];
		[self.renderingController update];
		[exporter captureFrameAtTime:CMTimeMake(frameNumber, 30)];
		frameNumber ++;

		// Update our progress bar
		// This has to happen on the main thread, because in iOS, everything that
		// touches the UI needs to happen on the main thread
		[self performSelectorOnMainThread:@selector(updateProgress:)
							   withObject:[NSNumber numberWithFloat:frameNumber/(float)totalFrames]
							waitUntilDone:NO];
	}
	
	[exporter finishRecording];
	
	// Temp: dump it into our photos album
	UISaveVideoAtPathToSavedPhotosAlbum(filepath, nil, nil, nil);
	
	// Show the text and button to let the user dismiss
	self.completionLabel.hidden = NO;
	self.completionButton.hidden = NO;

	// Start up our animation's render loop again
	self.renderingController.paused = NO;
}

- (void)updateProgress:(NSNumber*)newPercentProgress
{
	self.progressIndicator.progress = [newPercentProgress floatValue];
}

- (IBAction)dismiss:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

@end
