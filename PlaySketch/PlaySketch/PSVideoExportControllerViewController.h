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
@class PSAnimationRenderingController, PSDrawingDocument;

@interface PSVideoExportControllerViewController : UIViewController
@property(nonatomic,retain)IBOutlet UIProgressView* progressIndicator;
@property(nonatomic,retain)IBOutlet UILabel* completionLabel;
@property(nonatomic,retain)IBOutlet UIButton* completionButton;
@property(nonatomic,retain)PSAnimationRenderingController* renderingController;
@property(nonatomic,retain)PSDrawingDocument* document;

- (IBAction)dismiss:(id)sender;

@end
