/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <UIKit/UIKit.h>
#import "PSSelectionHelper.h"

@class PSDrawingGroup;

@interface PSGroupOverlayButtons : UIView
@property(nonatomic,retain)IBOutlet UIButton* recordingButton;
@property(nonatomic,retain)IBOutlet UIButton* createGroupButton;
@property(nonatomic,retain)IBOutlet UIButton* disbandGroupButton;
@property(nonatomic,retain)IBOutlet UIButton* deleteGroupButton;
@property(nonatomic) BOOL recordPulsing;

- (void)configureForSelectionCount:(int)count isLeafObject:(BOOL)isLeaf;
- (void)startRecordingMode;
- (void)stopRecordingMode;

@end
