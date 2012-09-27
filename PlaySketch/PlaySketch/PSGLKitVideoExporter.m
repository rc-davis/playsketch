/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */


// Heavily adapted from: http://www.developers-life.com/create-movie-from-array-of-images.html

#import "PSGLKitVideoExporter.h"
#import "PSHelpers.h"
#import "PSAnimationRenderingController.h"
#import <GLKit/GLKit.h>


@interface PSGLKitVideoExporter ()
@property(nonatomic,retain)AVAssetWriter* videoWriter;
@property(nonatomic,retain)AVAssetWriterInput* videoWriterInput;
@property(nonatomic,retain)AVAssetWriterInputPixelBufferAdaptor *pixelAdaptor;
@property(nonatomic,retain)GLKView* view;
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image;
@end


@implementation PSGLKitVideoExporter


- (id)initWithView:(GLKView*)view toPath:(NSString*)path
{
	if(self = [super init])
	{
		self.view = view;

		CGSize frameSize = view.frame.size;
		
		
		// Create the videoWriter (AVAssetWriter)
		// This takes frames from the AVAssetWriterInput to build a video
		NSError *error = nil;
		self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
													 fileType:AVFileTypeQuickTimeMovie
														error:&error];
		[PSHelpers assert:(!error) withMessage:[error description]];
		
		
		// Create the videoWriterInput (AVAssetWriterInput)
		NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
									   AVVideoCodecH264, AVVideoCodecKey,
									   [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
									   [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
									   nil];
		self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
																   outputSettings:videoSettings];
		
		
		// Create an "Adapter" for turning pixels into frames (?)
		NSDictionary* adapterAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
										   [NSNumber numberWithUnsignedInt:frameSize.width], kCVPixelBufferWidthKey,
										   [NSNumber numberWithUnsignedInt:frameSize.height], kCVPixelBufferHeightKey, nil];
		self.pixelAdaptor = [AVAssetWriterInputPixelBufferAdaptor
							 assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput
							 sourcePixelBufferAttributes:adapterAttributes];
		[self.videoWriter addInput:self.videoWriterInput];
		
		
		// Avoid having to set all of our timestamps?
		// TODO: can we get rid of this?
		self.videoWriterInput.expectsMediaDataInRealTime = YES;
		
	}
	return self;
}


- (void)beginRecording
{
	NSLog(@"Begin Video Recording...");
	
	//Start the session
	BOOL started = [self.videoWriter startWriting];
	[PSHelpers assert:started withMessage:@"Recordng Session should have started"];
	
	[self.videoWriter startSessionAtSourceTime:kCMTimeZero];

}


- (void)captureFrameAtTime:(CMTime)timestamp
{
	// This trusts that the state of the GLKView has already been set up
	// properly to correspond with the timestamp

	CVPixelBufferRef buffer = [self pixelBufferFromCGImage:self.view.snapshot.CGImage];
	
	if (buffer && self.pixelAdaptor.assetWriterInput.readyForMoreMediaData)
	{
		BOOL result = [self.pixelAdaptor appendPixelBuffer:buffer
									  withPresentationTime:timestamp];
		
		if (!result)
			NSLog(@"FAILURE APPENDING: %lld", timestamp.value);
		else
			NSLog(@"appended: %lld", timestamp.value);
	}
		
	if(buffer)
		CVBufferRelease(buffer);
	
}


- (void)finishRecording
{
	NSLog(@"Finish Video Recording...");
	// Finish the session
    [self.videoWriterInput markAsFinished];
    [self.videoWriter finishWriting];

	// Clean up our variables
    CVPixelBufferPoolRelease(self.pixelAdaptor.pixelBufferPool);
	self.pixelAdaptor = nil;
	self.videoWriter = nil;
	self.videoWriterInput = nil;
	
}


- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                        CGImageGetHeight(image), kCVPixelFormatType_32ARGB,
						(__bridge CFDictionaryRef) options,
                        &pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
                                                 CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@end
