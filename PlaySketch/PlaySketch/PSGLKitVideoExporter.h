/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <Foundation/Foundation.h>
@class PSAnimationRenderingController, AVAssetWriter, AVAssetWriterInput, AVAssetWriterInputPixelBufferAdaptor;

@interface PSGLKitVideoExporter : NSObject
//TODO: should be private
@property(nonatomic,retain)AVAssetWriter* videoWriter;
@property(nonatomic,retain)AVAssetWriterInput* videoWriterInput;
@property(nonatomic,retain)AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property(nonatomic,retain)PSAnimationRenderingController* renderController;
@property(nonatomic,retain)NSTimer* timer;

- (id)initWithController:(PSAnimationRenderingController*)rc;
- (void)addFrame;
- (void)finishRecording;
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image;

@end
