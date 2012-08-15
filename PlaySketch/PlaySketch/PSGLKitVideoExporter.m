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
#import <AVFoundation/AVFoundation.h>

@implementation PSGLKitVideoExporter
@synthesize videoWriter = _videoWriter;
@synthesize videoWriterInput = _videoWriterInput;
@synthesize adaptor = _adaptor;
@synthesize renderController = _renderController;
@synthesize timer = _timer;

- (id)initWithController:(PSAnimationRenderingController*)rc
{
	if(self == [super init])
	{
		self.renderController = rc;
		CGSize frameSize = rc.view.frame.size;
		
		//Generate a temporary URL for the file
		NSString* filename = [NSString stringWithFormat:@"%.0f.%@",
							  [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mp4"];
		NSString* filepath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
		NSURL* fileurl = [NSURL fileURLWithPath:filepath];
		NSLog(@"Creating temp file at path: %@", fileurl);
		
		
		// Create the videoWriter (AVAssetWriter)
		// This takes frames from the AVAssetWriterInput to build a video
		NSError *error = nil;
		self.videoWriter = [[AVAssetWriter alloc] initWithURL:fileurl
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
		self.adaptor = [AVAssetWriterInputPixelBufferAdaptor
				assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput
				sourcePixelBufferAttributes:adapterAttributes];
		[self.videoWriter addInput:self.videoWriterInput];
		

		//Avoid having to set all of our timestamps?
		self.videoWriterInput.expectsMediaDataInRealTime = YES;
		
		//Start the session
		BOOL start = [self.videoWriter startWriting];
		NSLog(@"Session started? %d", start);
		

		int frameNumber = 0;
		[self.videoWriter startSessionAtSourceTime:CMTimeMake(frameNumber, 30)];
		GLKView* view = (GLKView*)self.renderController.view;
		
		while (frameNumber < 30*1)
		{
			[self.renderController jumpToTime:frameNumber/30.0];
			[self.renderController update];
			
			CVPixelBufferRef buffer = [self pixelBufferFromCGImage:view.snapshot.CGImage];
			
			if (buffer && self.adaptor.assetWriterInput.readyForMoreMediaData)
			{
				BOOL result = [self.adaptor appendPixelBuffer:buffer
										 withPresentationTime:CMTimeMake(frameNumber, 30)];
				
				if (result == NO) //failes on 3GS, but works on iphone 4
					NSLog(@"failed to append buffer");
				else NSLog(@"appended: %d", frameNumber);
			}
			
			if(buffer)
				CVBufferRelease(buffer);
			
			frameNumber ++;
		}
		
		[self finishRecording];
	
		UISaveVideoAtPathToSavedPhotosAlbum(filepath, nil, nil, nil);
		
	}
	return self;
}

- (void)finishRecording
{
	//Finish the session:
    [self.videoWriterInput markAsFinished];
    [self.videoWriter finishWriting];
    CVPixelBufferPoolRelease(self.adaptor.pixelBufferPool);

	self.adaptor = nil;
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
